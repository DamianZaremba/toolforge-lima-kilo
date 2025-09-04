#!/bin/env python3
from __future__ import annotations

import json
import os
import platform
import re
import shutil
import subprocess
import tempfile
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, cast

import click
import requests

TOOLFORGE_DEPLOY_REPO = Path("~/toolforge-deploy").expanduser()
GITLAB_BASE_URL = "https://gitlab.wikimedia.org"
GITLAB_API_BASE_URL = f"{GITLAB_BASE_URL}/api/v4"
PACKAGE_JOB_NAME = "package:deb"
CHART_JOB_NAME = "publish-devchart-toolsbeta"
# Gotten from the gitlab group page
TOOLFORGE_GROUP_ID = 203
TOOLOFORGE_PACKAGE_REGISTRY_DIR = Path("~/.lima-kilo/installed_packages").expanduser()
COMPONENT_TO_PACKAGE = {
    "webservice-cli": "toolforge-webservice",
    "toolforge-weld": "python3-toolforge-weld",
    "toolforge-cli": "toolforge-cli",
}


def _do_get_dict(path: str, **kwargs) -> dict[str, Any]:
    if not path.startswith("http"):
        path = f"{GITLAB_API_BASE_URL}{path}"

    response = requests.get(path, **kwargs)
    response.raise_for_status()
    return response.json()


def _do_get_list(path: str, **kwargs) -> list[dict[str, Any]]:
    return cast(list[dict[str, Any]], _do_get_dict(path=path, **kwargs))


def _register_custom_package(mr_number: int, component: str) -> None:
    """We need this because the package versions don't have the mr information."""
    package = COMPONENT_TO_PACKAGE.get(component, f"toolforge-{component}")
    os.makedirs(TOOLOFORGE_PACKAGE_REGISTRY_DIR, exist_ok=True)
    package_file = TOOLOFORGE_PACKAGE_REGISTRY_DIR / package

    if mr_number == "restore":
        package_file.unlink(missing_ok=True)
        return

    package_file.write_text(json.dumps({"mr_number": mr_number}))


def get_project(component: str) -> dict[str, Any]:
    group_data = _do_get_dict(path=f"/groups/{TOOLFORGE_GROUP_ID}")
    for repo in group_data["projects"]:
        if repo["path"] == component:
            return repo

    component_list = [repo["path"] for repo in group_data["projects"]]
    raise Exception(
        f"Unable to find component {component} in toolforge, found: {component_list}"
    )


def get_mrs(project: dict[str, Any]) -> list[dict[str, Any]]:
    return _do_get_list(f"/projects/{project['id']}/merge_requests?state=opened")


def get_mr(project: dict[str, Any], mr_number: int) -> dict[str, Any]:
    return _do_get_dict(f"/projects/{project['id']}/merge_requests/{mr_number}")


def get_chart_job(project: dict[str, Any], pipeline: dict[str, Any]) -> dict[str, Any]:
    for job in _do_get_list(
        f"/projects/{project['id']}/pipelines/{pipeline['id']}/jobs"
    ):
        if job["name"] == CHART_JOB_NAME:
            return job

    raise Exception(
        f"Unable to find a chart job({CHART_JOB_NAME}) in pipeline {pipeline['web_url']}"
    )


def get_package_job(
    project_id: int, pipeline: dict[str, Any], arch: str
) -> dict[str, Any]:
    for job in _do_get_list(f"/projects/{project_id}/pipelines/{pipeline['id']}/jobs"):
        if job["name"].startswith(PACKAGE_JOB_NAME):
            if (
                job["name"] == PACKAGE_JOB_NAME
                or job["name"] == f"{PACKAGE_JOB_NAME}: [{arch}]"
            ):
                # The job is either just PACKAGE_JOB_NAME if the package is built for a single arch
                # or has the arch in as suffix if it was built for a specific arch, currently this only
                # affects miscools-clli
                return job
            else:
                print(
                    f"ignoring job '{job['name']}', not '{PACKAGE_JOB_NAME}' or '{PACKAGE_JOB_NAME}: [{arch}]'"
                )

    raise Exception(
        f"Unable to find a package job({PACKAGE_JOB_NAME}) in pipeline {pipeline['web_url']}"
    )


def get_last_pipeline(project: dict[str, Any], mr_number: int) -> dict[str, Any]:
    mr_data = get_mr(project=project, mr_number=mr_number)
    while mr_data["head_pipeline"]["status"] in ["running", "created"]:
        click.echo(
            f"Pipeline {mr_data['head_pipeline']['iid']} is still running, waiting for it to finish...."
        )
        time.sleep(10)
        mr_data = get_mr(project=project, mr_number=mr_number)

    if mr_data["head_pipeline"]["status"] != "success":
        raise Exception(
            f"Unable to find a successful pipeline for MR {mr_number} ({mr_data['web_url']}), last pipeline status: "
            f"{mr_data['head_pipeline']['status']}"
        )

    return mr_data["head_pipeline"]


def deploy_package_mr(component: str, mr_number: int, arch: str) -> None:
    project = get_project(component=component)
    pipeline = get_last_pipeline(project=project, mr_number=mr_number)
    # this allows using pipelines for forks
    pipeline_project_id = pipeline["project_id"]
    package_job = get_package_job(
        project_id=pipeline_project_id, pipeline=pipeline, arch=arch
    )
    artifact_response = requests.get(
        f"{GITLAB_API_BASE_URL}/projects/{pipeline_project_id}/jobs/{package_job['id']}/artifacts"
    )
    artifact_response.raise_for_status()
    with tempfile.TemporaryDirectory() as tempdir:
        artifacts_path = f"{tempdir}/artifacts.zip"
        Path(artifacts_path).open("wb").write(artifact_response.content)
        shutil.unpack_archive(artifacts_path, tempdir)

        subprocess.check_call(["ls", "-lR", f"{tempdir}"])
        click.echo(f"Downloaded artifacts at {tempdir}:")
        debs = list((Path(tempdir) / "debs").glob(pattern="*.deb"))
        # Needed as apt install might still not install the file if there's a better alternative in the repos
        install_command = [
            "sudo",
            "dpkg",
            "-i",
        ] + debs
        subprocess.check_call(install_command)

        # Needed as the previous one does not install dependencies
        fix_deps_command = [
            "sudo",
            "DEBIAN_FRONTEND=noninteractive",
            "apt",
            "install",
            "--yes",
            "--fix-missing",
        ]
        subprocess.check_call(fix_deps_command)

    _register_custom_package(mr_number=mr_number, component=component)
    click.secho(f"Deployed {component} from mr {mr_number}", fg="green")


def restore_chart(component: str) -> None:
    try:
        subprocess.check_call(["git", "reset", "--hard"], cwd=TOOLFORGE_DEPLOY_REPO)
        subprocess.check_call(["./deploy.sh", component], cwd=TOOLFORGE_DEPLOY_REPO)
    except subprocess.CalledProcessError as error:
        click.secho(f"Failed to restore {component}: {error}", fg="yellow")
        return

    click.secho(f"Restored {component} to the version in toolforge-deploy", fg="green")


def restore_package(component: str) -> None:
    # this can be removed if we make the package name patterns all the same
    package = COMPONENT_TO_PACKAGE.get(component, f"toolforge-{component}")

    check_command = [
        "sudo",
        "apt",
        "policy",
        package,
    ]

    remove_command = [
        "sudo",
        "env",
        "DEBIAN_FRONTEND=noninteractive",
        "apt",
        "remove",
        "--yes",
        package,
    ]

    install_command = [
        "sudo",
        "env",
        "DEBIAN_FRONTEND=noninteractive",
        "apt",
        "install",
        "--yes",
        "--reinstall",
        "--allow-downgrades",
        package,
    ]

    check_output = subprocess.check_output(check_command, cwd=TOOLFORGE_DEPLOY_REPO)
    if "Unable to locate package" not in check_output.decode("utf-8"):
        try:
            subprocess.check_call(remove_command, cwd=TOOLFORGE_DEPLOY_REPO)
        except subprocess.CalledProcessError as error:
            click.secho(f"Failed to restore {component}: {error}", fg="yellow")
            return

    try:
        subprocess.check_call(install_command, cwd=TOOLFORGE_DEPLOY_REPO)

    except subprocess.CalledProcessError as error:
        click.secho(f"Failed to restore {component}: {error}", fg="yellow")
        return

    click.secho(f"Restored {component} to the version in toolforge-deploy", fg="green")


def deploy_chart_mr(component: str, mr_number: int) -> None:
    project = get_project(component=component)
    pipeline = get_last_pipeline(project=project, mr_number=mr_number)
    # to be able to use charts built in forks, we will have to re-think how we push images and such
    chart_job = get_chart_job(project=project, pipeline=pipeline)
    # for some silly reason the jobs gitlab api needs a token to get the logs
    # but the non-api url is public, so we use the public one
    logs_response = requests.get(
        f"{GITLAB_BASE_URL}/repos/cloud/toolforge/{project['path']}/-/jobs/{chart_job['id']}/trace.json"
    )
    logs_response.raise_for_status()
    chart_version = ""
    for line in logs_response.json()["lines"]:
        for content in line["content"]:
            if content["text"].startswith("Pushed: "):
                chart_version = content["text"].rsplit(":", 1)[-1].strip()

    if chart_version == "":
        message = "Unable to retrieve chart version from logs:\n"
        message += "\n".join(logs_response.json()["lines"])
        raise Exception(message)

    print(f"Found chart version '{chart_version}'")
    values_files = [
        TOOLFORGE_DEPLOY_REPO / "components" / component / "values" / "local.yaml",
        TOOLFORGE_DEPLOY_REPO
        / "components"
        / component
        / "values"
        / "local.yaml.gotmpl",
    ]
    for values_file in values_files:
        if values_file.exists():
            break
    else:
        raise Exception(
            f"Unable to find values file for component {component}, none of {values_files} was found"
        )

    values_data = values_file.read_text()
    fixed_lines: list[str] = []
    for line in values_data.splitlines():
        if line.startswith("chartVersion"):
            line = f"chartVersion: {chart_version}"
        elif line.startswith("chartRepository:"):
            line = "chartRepository: toolsbeta"

        fixed_lines.append(line)

    values_file.write_text("\n".join(fixed_lines))

    try:
        output = subprocess.check_output(
            ["./deploy.sh", component],
            cwd=TOOLFORGE_DEPLOY_REPO,
            # avoid interactive mode
            stdin=subprocess.DEVNULL,
        ).decode("utf-8")
    except subprocess.CalledProcessError:
        if datetime.strptime(
            pipeline["finished_at"].rsplit(".", 1)[0], "%Y-%m-%dT%H:%M:%S"
        ) < (datetime.now() - timedelta(days=1)):
            click.secho(
                f"Failed to deploy, maybe the CI run is too old (from {pipeline['finished_at']}), you can try rerunning the pipeline:",
                fg="yellow",
            )
            click.secho(
                f"    https://gitlab.wikimedia.org/repos/cloud/toolforge/{component}/-/merge_requests/{mr_number}/pipelines",
                fg="yellow",
            )
            return

        click.secho(
            "Error trying to deploy, check the logs for hints.",
            fg="red",
        )
        raise click.Abort()

    click.secho(output)

    if "has changed:" not in output:
        click.secho(
            "  Trying to do a rollout reboot of the deployments of that chart as it seems there was no chart diff..."
        )
        maybe_namespace = re.search("namespace=(.*)$", output, flags=re.MULTILINE)
        if maybe_namespace:
            rollout_reboot_deployments(namespace=maybe_namespace.groups()[0])
        else:
            click.secho(
                "  Unable to find the namespace to do a rollout reboot, you might have to restart the pods yourself to pull the latest image"
            )

    click.secho(f"Deployed {component}:{chart_version} from mr {mr_number}", fg="green")


def rollout_reboot_deployments(namespace: str) -> None:
    deployments = subprocess.check_output(
        ["kubectl", "get", "deployments", f"--namespace={namespace}", "--output=name"]
    ).decode("utf-8")
    for deployment in deployments.splitlines():
        subprocess.check_call(
            ["kubectl", "rollout", "restart", f"--namespace={namespace}", deployment]
        )


def ask_mr(component: str) -> int:
    project = get_project(component=component)
    all_mrs = get_mrs(project=project)
    choices = ["restore"]
    for mr in all_mrs:
        click.secho(
            f"  * {mr['iid']}: <{mr['author']['username']}> {mr['title']}",
            fg="yellow",
        )
        choices.append(str(mr["iid"]))

    chosen = click.prompt(
        "Which MR do you want to deploy?",
        type=click.Choice(choices=choices),
        default=choices[1] if all_mrs else choices[0],
    )
    return chosen


def _try_mr_number_option(maybe_mr_number: Any) -> Any:
    try:
        return int(maybe_mr_number)
    except ValueError:
        if maybe_mr_number == "restore":
            return "restore"

    raise ValueError(f"Unknown mr_number {maybe_mr_number}, must be int or 'restore'.")


@click.command()
@click.argument("component", required=True)
@click.option(
    "--arch", default="amd64" if platform.machine() in ["x86_64", ""] else "arm64"
)
@click.argument(
    "mr_number",
    type=_try_mr_number_option,
    required=False,
    default=None,
)
def main(component: str, mr_number: int | str | None = None, arch: str = "amd64"):
    """
    Deploy a specific version of a toolforge component or client package.

    MR_NUMBER is the number of the MR to deploy or `restore` to deploy the version from toolforge-deploy. If not passed
    will ask interactively fetching the open MRs list from gitlab.
    """
    if mr_number is None:
        mr_number = ask_mr(component=component)

    if component.endswith("-cli") or component in [
        "tools-webservice",
        "toolforge-weld",
    ]:
        if mr_number == "restore":
            restore_package(component=component)
        else:
            deploy_package_mr(component=component, mr_number=int(mr_number), arch=arch)
    else:
        if mr_number == "restore":
            restore_chart(component=component)
        else:
            deploy_chart_mr(component=component, mr_number=int(mr_number))


if __name__ == "__main__":
    main()

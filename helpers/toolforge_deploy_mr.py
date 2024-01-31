#!/bin/env python3
from __future__ import annotations
from pathlib import Path
import shutil
import subprocess
import tempfile
from datetime import datetime, timedelta

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


def _do_get_dict(path: str, **kwargs) -> dict[str, Any]:
    if not path.startswith("http"):
        path = f"{GITLAB_API_BASE_URL}{path}"

    response = requests.get(path, **kwargs)
    response.raise_for_status()
    return response.json()


def _do_get_list(path: str, **kwargs) -> list[dict[str, Any]]:
    return cast(list[dict[str, Any]], _do_get_dict(path=path, **kwargs))


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
    project: dict[str, Any], pipeline: dict[str, Any]
) -> dict[str, Any]:
    for job in _do_get_list(
        f"/projects/{project['id']}/pipelines/{pipeline['id']}/jobs"
    ):
        if job["name"] == PACKAGE_JOB_NAME:
            return job

    raise Exception(
        f"Unable to find a package job({PACKAGE_JOB_NAME}) in pipeline {pipeline['web_url']}"
    )


def get_last_pipeline(mr_data: dict[str, Any], mr_number: int) -> dict[str, Any]:
    if mr_data["head_pipeline"]["status"] != "success":
        raise Exception(
            f"Unable to find a successful pipeline for MR {mr_number} ({mr_data['web_url']})"
        )

    return mr_data["head_pipeline"]


def deploy_package_mr(component: str, mr_number: int) -> None:
    project = get_project(component=component)
    mr_data = get_mr(project=project, mr_number=mr_number)
    pipeline = get_last_pipeline(mr_data=mr_data, mr_number=mr_number)
    package_job = get_package_job(project=project, pipeline=pipeline)
    artifact_response = requests.get(
        f"{GITLAB_API_BASE_URL}/projects/{project['id']}/jobs/{package_job['id']}/artifacts"
    )
    with tempfile.TemporaryDirectory() as tempdir:
        artifacts_path = f"{tempdir}/artifacts.zip"
        Path(artifacts_path).open("wb").write(artifact_response.content)
        shutil.unpack_archive(artifacts_path, tempdir)

        subprocess.check_call(["ls", "-lR", f"{tempdir}"])
        click.echo(f"Downloaded artifacts at {tempdir}:")
        debs = list((Path(tempdir) / "debs").glob(pattern="*.deb"))
        command = ["sudo", "apt", "install", "--yes", "--allow-downgrades"] + debs
        subprocess.check_call(command)


def deploy_chart_mr(component: str, mr_number: int) -> None:
    project = get_project(component=component)
    mr_data = get_mr(project=project, mr_number=mr_number)
    pipeline = get_last_pipeline(mr_data=mr_data, mr_number=mr_number)
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
    fixed_lines = [
        f"chartVersion: {chart_version}" if line.startswith("chartVersion") else line
        for line in values_data.splitlines()
    ]
    values_file.write_text("\n".join(fixed_lines))
    try:
        subprocess.check_call(["./deploy.sh", component], cwd=TOOLFORGE_DEPLOY_REPO)
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

    click.secho(f"Deployed {component}:{chart_version} from mr {mr_number}", fg="green")


def ask_mr(component: str) -> int:
    project = get_project(component=component)
    all_mrs = get_mrs(project=project)
    choices = []
    for mr in all_mrs:
        click.secho(
            f"  * {mr['iid']}: <{mr['author']['username']}> {mr['title']}",
            fg="yellow",
        )
        choices.append(str(mr["iid"]))

    chosen = click.prompt(
        "Which MR do you want to deploy?",
        type=click.Choice(choices=choices),
    )
    return int(chosen)


@click.command()
@click.argument("component", required=True)
@click.argument("mr_number", type=int, required=False, default=None)
def main(component: str, mr_number: int | None = None):
    if mr_number is None:
        mr_number = ask_mr(component=component)

    if component.endswith("-cli"):
        deploy_package_mr(component=component, mr_number=mr_number)
    else:
        deploy_chart_mr(component=component, mr_number=mr_number)


if __name__ == "__main__":
    main()

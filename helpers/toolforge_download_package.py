#!/bin/env python3
from __future__ import annotations
from pathlib import Path
import shutil
import subprocess
import tempfile

from typing import Any, cast
import click
import requests


GITLAB_BASE_URL = "https://gitlab.wikimedia.org/api/v4"
PACKAGE_JOB_NAME = "package:deb"
# Gotten from the gitlab group page
TOOLFORGE_GROUP_ID = 203


def _do_get(path: str, **kwargs) -> dict[str, Any]:
    if not path.startswith("http"):
        path = f"{GITLAB_BASE_URL}{path}"

    response = requests.get(path, **kwargs)
    response.raise_for_status()
    return response.json()


def _do_get_list(path: str, **kwargs) -> list[dict[str, Any]]:
    return cast(list[dict[str, Any]], _do_get(path, **kwargs))


def get_project(component: str) -> dict[str, Any]:
    group_data = _do_get(path=f"/groups/{TOOLFORGE_GROUP_ID}")
    for repo in group_data["projects"]:
        if repo["path"] == component:
            return repo

    component_list = [repo["path"] for repo in group_data["projects"]]
    raise Exception(
        f"Unable to find component {component} in toolforge, found: {component_list}"
    )


def get_mr(project: dict[str, Any], mr_number: int) -> dict[str, Any]:
    return _do_get(f"/projects/{project['id']}/merge_requests/{mr_number}")


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


@click.command()
@click.argument("component", required=True)
@click.argument("mr_number", required=True, type=int)
def main(component: str, mr_number: int):
    project = get_project(component=component)
    mr_data = get_mr(project=project, mr_number=mr_number)
    pipeline = get_last_pipeline(mr_data=mr_data, mr_number=mr_number)
    package_job = get_package_job(project=project, pipeline=pipeline)
    artifact_response = requests.get(
        f"{GITLAB_BASE_URL}/projects/{project['id']}/jobs/{package_job['id']}/artifacts"
    )
    with tempfile.TemporaryDirectory() as tempdir:
        artifacts_path = f"{tempdir}/artifacts.zip"
        Path(artifacts_path).open("wb").write(artifact_response.content)
        shutil.unpack_archive(artifacts_path, "./artifacts")

    click.echo("Downloaded artifacts at ./artifacts:")
    subprocess.check_call(["ls", "-lR", "./artifacts"])


if __name__ == "__main__":
    main()

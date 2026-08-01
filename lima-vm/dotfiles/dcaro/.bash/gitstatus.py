#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
import sys
from subprocess import PIPE, Popen

# change those symbols to whatever you prefer
symbols = {"ahead of": "↑·", "behind": "↓·", "prehash": ":"}
gitsym = Popen(["git", "symbolic-ref", "HEAD"], stdout=PIPE, stderr=PIPE)
branch, error = gitsym.communicate()

error_string = error.decode("utf-8")

if "fatal: not a git repository" in error_string:
    sys.exit(0)

branch = branch.decode("utf-8").strip()[11:]

res, err = Popen(
    ["git", "diff", "--name-status"], stdout=PIPE, stderr=PIPE
).communicate()
err_string = err.decode("utf-8")
if "fatal" in err_string:
    sys.exit(0)
changed_files = [namestat[0] for namestat in res.splitlines()]
staged_files = [
    namestat[0]
    for namestat in Popen(["git", "diff", "--staged", "--name-status"], stdout=PIPE)
    .communicate()[0]
    .splitlines()
]
nb_changed = len(changed_files) - changed_files.count("U")
nb_U = staged_files.count("U")
nb_staged = len(staged_files) - nb_U
staged = str(nb_staged)
conflicts = str(nb_U)
changed = str(nb_changed)
nb_untracked = len(
    Popen(["git", "ls-files", "--others", "--exclude-standard"], stdout=PIPE)
    .communicate()[0]
    .splitlines()
)
untracked = str(nb_untracked)
if not nb_changed and not nb_staged and not nb_U and not nb_untracked:
    clean = "1"
else:
    clean = "0"

remote = ""

if not branch:  # not on any branch
    branch = (
        symbols["prehash"]
        + Popen(["git", "rev-parse", "--short", "HEAD"], stdout=PIPE)
        .communicate()[0][:-1]
        .decode()
    )
else:
    remote_name = (
        Popen(["git", "config", f"branch.{branch}.remote"], stdout=PIPE)
        .communicate()[0]
        .strip()
    )
    if remote_name:
        merge_name = (
            Popen(["git", "config", f"branch.{branch}.merge"], stdout=PIPE)
            .communicate()[0]
            .strip()
        )
        if remote_name == ".":  # local
            remote_ref = merge_name
        else:
            remote_ref = f"refs/remotes/{remote_name}/{merge_name[11:]}"
        revgit = Popen(
            ["git", "rev-list", "--left-right", f"{remote_ref}...HEAD"],
            stdout=PIPE,
            stderr=PIPE,
        )
        revlist = revgit.communicate()[0]
        if revgit.poll():  # fallback to local
            revlist = Popen(
                ["git", "rev-list", "--left-right", f"{merge_name}...HEAD"],
                stdout=PIPE,
                stderr=PIPE,
            ).communicate()[0]
        behead = revlist.splitlines()
        ahead = len([x for x in behead if x[0] == ">"])
        behind = len(behead) - ahead
        if behind:
            remote += f"{symbols['behind']}{behind}"
        if ahead:
            remote += f"{symbols['ahead of']}{ahead}"

if remote == "":
    remote = "."

out = "\n".join(
    [str(branch), str(remote), staged, conflicts, changed, untracked, clean]
)
print(out)

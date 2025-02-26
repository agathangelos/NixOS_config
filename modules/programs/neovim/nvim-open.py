#!/usr/bin/env python3

import hashlib
import os
import socket
import sys
from pathlib import Path

import nvr


def find_project_root(initial_path: Path) -> Path:
    project_files = [
        ".git",
        "_darcs",
        ".hg",
        ".bzr",
        ".svn",
        "Makefile",
        "package.json",
        "setup.py",
        "setup.cfg",
        "pyproject.toml",
        "flake.nix",
        "Cargo.toml",
    ]
    for project_file in project_files:
        path = initial_path
        while path.parent != path:
            if (path / project_file).exists():
                return path
            path = path.parent
    return initial_path


def main() -> None:
    line = "0"
    project_root = Path(os.getcwd())
    if len(sys.argv) >= 2:
        path = Path(sys.argv[1])
        args = path.name.split(":")
        # len == 2: file:line, len == 3: file:line:column
        if len(args) == 2 or len(args) == 3:
            path = path.parent.joinpath(args[0])
            if path.exists():
                line = args[1]
                sys.argv[1] = str(path.resolve())
        if path.is_file():
            project_root = find_project_root(path.parent.resolve())
        else:
            project_root = path.parent.resolve()

    sock_hash = hashlib.md5(str(project_root).encode("utf-8")).hexdigest()
    sock = Path.home().joinpath(".data/nvim/").joinpath(f"sock-{sock_hash}")

    if os.path.exists(sock):
        # cleanup stale socket
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(str(sock))
        except ConnectionRefusedError:
            os.remove(sock)

    os.environ["TTY"] = str(os.ttyname(sys.stdout.fileno()))
    os.environ["NVIM_LISTEN_ADDRESS"] = str(sock)

    vim_commands = ""
    if project_root.exists():
        if project_root.is_dir():
            vim_commands = f"lcd {project_root}"
    else:
        try:
            project_root.mkdir(parents=True, exist_ok=True)
            vim_commands += f"lcd {project_root}"
        except OSError:
            pass
    vim_commands += " | RaiseTmuxPane"

    args = [
        "nvr",
        f"+{line}",
        "-cc",
        vim_commands,
        "--remote-silent",
        "-s",
    ] + sys.argv[1:]
    return nvr.main(args)


if __name__ == "__main__":
    main()

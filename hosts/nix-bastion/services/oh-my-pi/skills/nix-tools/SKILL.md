---
name: nix-tools
description: Obtain missing commands, formatters, linters, archive tools and network diagnostics on demand with nix run, nix shell or a project's dev shell in the OMP NixOS container.
---

# On-demand tools in the OMP container

The persistent baseline is Git, curl, jq, Python and the agent runtimes, plus
NixOS base utilities. Use OMP's read, search and edit tools when they cover the
operation. Do not assume optional command-line tools are installed; check with
`command -v <command>` before use.

## Prefer the project's environment

Follow the repository's documented commands and use its dev shell when one is
provided. This keeps tool versions and dependencies aligned with the project:

```sh
nix develop -c just check
```

Use the repository's actual recipe or command, not `just check` blindly. For a
legacy `shell.nix`, use `nix-shell --run '<command> [args...]'`.

## One tool: nix run

Run a package's default executable without adding it to a profile:

```sh
nix run nixpkgs#nixfmt -- --check path/to/module.nix
nix run nixpkgs#statix -- check path/to/module.nix
nix run nixpkgs#deadnix -- --fail path/to/module.nix
nix run nixpkgs#shellcheck -- path/to/script.sh
nix run nixpkgs#shfmt -- -d path/to/script.sh
nix run nixpkgs#just -- --list
```

Arguments after `--` go to the tool. In this container, the `nixpkgs` registry is
pinned to the host configuration's flake input.

## Specific binaries or multiple tools: nix shell

Use `nix shell -c` when a package has multiple executables, the desired executable
is not its default, or several tools need to share an environment:

```sh
nix shell nixpkgs#yq-go -c yq -o=json '.services' config.yaml
nix shell nixpkgs#sqlite -c sqlite3 database.sqlite '.tables'
nix shell nixpkgs#dnsutils -c dig example.org A
nix shell nixpkgs#openssl -c openssl version
nix shell nixpkgs#zip nixpkgs#unzip -c sh -c 'zip -q archive.zip file.txt && unzip -l archive.zip'
nix shell nixpkgs#nixfmt nixpkgs#statix nixpkgs#deadnix -c sh -c 'nixfmt --check module.nix && statix check module.nix && deadnix --fail module.nix'
```

After `-c`, pass the executable and arguments separately. Do not write
`-c "dig example.org A"`; use `-c dig example.org A`. Shell operators such as
`&&`, pipes and redirections require an explicit `sh -c '...'` inside the
Nix environment. Prefer finite commands over opening an interactive shell.
The added PATH entries apply only to that command and its children, not to the
next tool call.

Other useful package/binary mappings:

| Nixpkgs package | Command |
| --- | --- |
| `ripgrep` | `rg` |
| `fd` | `fd` |
| `file` | `file` |
| `lsof` | `lsof` |
| `strace` | `strace` |

If the package name is unknown, use `nix search nixpkgs <query>`. Let evaluation,
build and command failures surface; inspect the error rather than installing a
substitute silently. Nix can fetch cached packages or build them on the host
through the container's shared daemon; it does not grant extra runtime
capabilities to diagnostics such as strace.

## Keep acquisition ephemeral

Do not use apt, npm global installs, pip installs, copied binaries, sudo or
`nix profile install` to obtain task-specific tools. Do not add a package to the
container configuration just because one task needs it. Scope credentials only
to commands that need them; fetching a tool is not a reason to import host
secrets, signing configuration or Home Manager.

# OpenCode Box

***Inspired by***: https://github.com/faileon/agent-containers/tree/main/open-code

This repository builds a Debian-based `opencode` environment so you can run the OpenCode AI agent inside an isolated container while working against your local project directory.


## What It Includes

- A reusable base image with common development and DevOps tooling
- A dedicated non-root `agent` user inside the container
- OpenCode CLI plus Claude Code installed globally
- Support for working against your current local repository via a bind mount

The box is set up with several DevOps-oriented tools in the image, including:

- `aws`
- `kubectl`
- `terraform`
- `tofu`
- `gh`
- `go`
- `pipx` and `ansible`
- `git`, `curl`, `jq`, `ripgrep`, `python3`, `node`, `npm`, `bun`, and other common CLI utilities

## Build

Use the top-level `Makefile`:

```bash
make open-code
```

To build the image and install the launcher into `~/.local/bin` in one step:

```bash
make install-open-code
```

This builds:

- `agent-base` from `base/Dockerfile`
- `open-code` from `open-code/Dockerfile`

## Install The Launcher

To install `opencode-box` automatically into `~/.local/bin`:

```bash
make install
```

You can override the destination if needed:

```bash
make install INSTALL_DIR=/somewhere/on/your/path
```

## Run

Use the wrapper script at `open-code/opencode-box`, or run the installed `opencode-box` command after `make install`.

It starts the container interactively, loads credentials from `~/.config/opencode/credentials.env` when present, and mounts:

- your current working directory to `/app`
- your OpenCode state and config directories
- your AWS config from `~/.aws`
- your GitHub CLI config from `~/.config/gh`
- your Kubernetes config from `~/.kube`

Those host directories are mounted into the container under `/home/agent`.

Example:

```bash
./open-code/opencode-box
opencode-box
```

Or pass a command directly:

```bash
./open-code/opencode-box aws sts get-caller-identity --profile personal
./open-code/opencode-box gh auth status
./open-code/opencode-box kubectl config get-contexts
```

## Runtime Behavior

On startup, the container entrypoint:

- switches to `/app`
- runs the requested command, such as `opencode`, `bash`, or `aws`

## Notes

- The wrapper currently uses the `open-code` image tag
- AWS paging is disabled in the wrapper so `aws` commands work even if a pager is unavailable
- GitHub CLI preferences come from the `~/.config/gh` mount, but API auth can be provided through `~/.config/opencode/credentials.env`
- `host.docker.internal` is added so tools in the container can access services running on your host machine

### Credentials

For secrets needed inside the container, create `~/.config/opencode/credentials.env` on the host.

Example:

```dotenv
GH_TOKEN=your_github_token_here
```

The wrapper passes that file to Docker with `--env-file` when it exists. This is the recommended way to provide GitHub authentication when your host `gh` stores tokens in a system credential store instead of `~/.config/gh/hosts.yml`.

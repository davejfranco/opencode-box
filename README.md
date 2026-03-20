# OpenCode Box

***Inspired by***: https://github.com/faileon/agent-containers/tree/main/open-code

This repository builds a containerized `opencode` environment so you can run the OpenCode AI agent inside an isolated container while working against your local project directory.


## What It Includes

- A reusable base image with common development and DevOps tooling
- OpenCode CLI plus Claude Code installed globally
- A bundled Claude Max proxy started automatically on container launch
- Support for working against your current local repository via a bind mount

The box is set up with several DevOps-oriented tools in the image, including:

- `aws`
- `kubectl`
- `terraform`
- `tofu`
- `git`, `curl`, `jq`, `ripgrep`, `python3`, and other common CLI utilities

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

- `agent-base:dev` from `base/Dockerfile`
- `open-code:dev` from `open-code/Dockerfile`

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

It starts the container interactively and mounts:

- your current working directory to `/app`
- your OpenCode state and config directories
- your AWS config from `~/.aws`
- your Kubernetes config from `~/.kube`

Example:

```bash
./open-code/opencode-box
opencode-box
```

Or pass a command directly:

```bash
./open-code/opencode-box aws sts get-caller-identity --profile personal
./open-code/opencode-box kubectl config get-contexts
```

## Runtime Behavior

On startup, the container entrypoint:

- starts the Claude Max proxy
- waits for the proxy health check to pass
- points OpenCode's Anthropic traffic at the local proxy
- runs the requested command, such as `opencode`, `bash`, or `aws`

## Notes

- The wrapper currently uses the `open-code:dev` image tag
- AWS paging is disabled in the wrapper so `aws` commands work even if a pager is unavailable
- `host.docker.internal` is added so tools in the container can access services running on your host machine

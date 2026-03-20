# Open Code

This image packages `opencode` into a containerized development box so you can run the agent against your local repository without installing everything directly on your host.

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

You can add more apt-installed tools by extending `LOCAL_TOOLS` in the top-level `Makefile`.

## Install The Launcher

To install `opencode-box` automatically into `~/.local/bin`:

```bash
make install
```

To install it somewhere else:

```bash
make install INSTALL_DIR=/somewhere/on/your/path
```

## What's In The Box

The image includes:

- `opencode-ai`
- `@anthropic-ai/claude-code`
- Claude Max proxy, started automatically by the entrypoint
- DevOps tooling such as `aws`, `kubectl`, `terraform`, and `tofu`
- Common CLI tools including `git`, `curl`, `jq`, `ripgrep`, `python3`, and Bun

## Run

Use `open-code/opencode-box` as the wrapper script, or install it with `make install` so it is available as `opencode-box` from your shell.

Startup is slightly slower because the container boots first, but that cost gives you an isolated and repeatable runtime.

The wrapper:

- adds `host.docker.internal` so the container can reach services running on your host
- mounts your current project into `/app`
- mounts OpenCode state, share, and config directories
- mounts your AWS config from `~/.aws`
- mounts your Kubernetes config from `~/.kube`
- disables AWS CLI paging so `aws` commands work without depending on a pager in the runtime

Current wrapper script:

```bash
#!/usr/bin/env bash

PROJ="$(basename "$(pwd)")"
NAME="open-code-${PROJ}"

exec docker run --rm --tty --interactive \
  --name "$NAME" \
  --add-host=host.docker.internal:host-gateway \
  -e AWS_PAGER="" \
  -v "$HOME/.aws:/home/node/.aws" \
  -v "$HOME/.kube:/home/node/.kube" \
  -v "$HOME/.local/state/opencode:/home/node/.local/state/opencode" \
  -v "$HOME/.local/share/opencode:/home/node/.local/share/opencode" \
  -v "$HOME/.config/opencode:/home/node/.config/opencode" \
  -v "$(pwd):/app:rw" \
  open-code:dev "$@"
```

Example usage:

```bash
./open-code/opencode-box
opencode-box
./open-code/opencode-box aws sts get-caller-identity --profile personal
./open-code/opencode-box kubectl config get-contexts
```

## Runtime Flow

On container startup, `entrypoint.sh`:

- starts the Claude Max proxy in the background
- waits for its health endpoint to become ready
- points Anthropic-compatible traffic at the local proxy
- executes the requested command

## References

- [Documentation](https://opencode.ai/docs)
- [GitHub Repo](https://github.com/sst/opencode)

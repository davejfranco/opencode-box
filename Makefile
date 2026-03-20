.PHONY: clean base open-code install install-open-code

# Determine container engine (podman or docker)
CONTAINER_ENGINE := $(shell which podman 2>/dev/null || which docker 2>/dev/null)

# UID/GID
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)

# Tools to install in to the containers with apt-get
LOCAL_TOOLS := "git curl jq ripgrep vim nano make zip unzip openssh-client wget tree imagemagick build-essential python3 python3-pip ca-certificates gnupg less groff-base"

# Launcher install location
INSTALL_DIR ?= $(HOME)/.local/bin

# Ensure we have a container engine
ifeq ($(CONTAINER_ENGINE),)
$(error No container engine (podman/docker) found in PATH)
endif

base:
	@echo "Building base image"
	$(CONTAINER_ENGINE) build \
		--build-arg HOST_UID=$(HOST_UID) \
		--build-arg HOST_GID=$(HOST_GID) \
		--build-arg LOCAL_TOOLS=$(LOCAL_TOOLS) \
		-t agent-base \
		-f base/Dockerfile base

open-code: base
	@echo "Building open-code"
	$(CONTAINER_ENGINE) build \
		--no-cache \
		-t open-code \
		-f open-code/Dockerfile open-code

install:
	@echo "Installing opencode-box to $(INSTALL_DIR)"
	mkdir -p "$(INSTALL_DIR)"
	install -m 0755 open-code/opencode-box "$(INSTALL_DIR)/opencode-box"
	@case ":$$PATH:" in \
		*:"$(INSTALL_DIR)":*) ;; \
		*) echo "Warning: $(INSTALL_DIR) is not on PATH" ;; \
	esac

install-open-code: open-code install

clean:
	@echo "Removing container images"
	@for image in open-code claude-code openai-codex agent-base; do \
		if $(CONTAINER_ENGINE) image inspect $$image > /dev/null 2>&1; then \
			echo "Removing $$image"; \
			$(CONTAINER_ENGINE) rmi -f $$image; \
		else \
			echo "Image $$image does not exist, skipping"; \
		fi; \
	done

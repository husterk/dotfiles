# Globally declared arguments (available to all build stages).
# Note: Each build stage must pull in the arguments that it needs.
ARG ARG_DEVCONTAINER_CLI
ARG ARG_DEVCONTAINER_USER
ARG ARG_BUN_VERSION

# -----------------------------------------------------------------------------------------
# -- STAGE 1: ADD CUSTOM CONTAINER INIT STEPS HERE                                       --
# -----------------------------------------------------------------------------------------
# Base Ubuntu image was selected to closely match the image used within the GitHub Actions
# CI/CD pipeline runners.
# Available Images: https://github.com/devcontainers/images/tree/main/src/base-ubuntu
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS devcontainer_base

# Pull in the globally declared args
ARG ARG_DEVCONTAINER_CLI
ARG ARG_DEVCONTAINER_USER
ARG ARG_BUN_VERSION

# Switch to the user specified in the globally declared args.
USER ${ARG_DEVCONTAINER_USER}

# Warn developers that this container is not meant to be built directly. It should only be
# built as a VSCode devcontainer.
RUN if [[ -z "$ARG_DEVCONTAINER_CLI" ]] ; \
    then printf "\nERROR: This Dockerfile needs to be built with VS Code !" && exit 1; \
    else printf "VS Code is detected: $ARG_DEVCONTAINER_CLI"; fi

# Define a directory for all files related to the devcontainer initialization process.
WORKDIR /devcontainer-init

# Prevent warnings from displaying when working with the OS.
ENV DEBIAN_FRONTEND=noninteractive

# Switch to the `root` user to ensure that the OS updates are applied properly.
USER root

# Update all local OS apps to resolve potential CVEs within the base image.
# Install required tools for the generate-config.sh script
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        gettext-base \
        wget \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch to the `root` user to ensure that NodeJS is installed properly.
USER root

# Install Bun for all users and verify the installation by running the version command.
# See: https://bun.sh/docs/installation#macos-and-linux
# See: https://abdusfauzi.com/2023/11/03/how-to-install-bun-sh-for-global-ubuntu-users-other-than-root/
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${ARG_BUN_VERSION}" && \
    mkdir -p /usr/local/.bun && \
    cp -R /root/.bun /usr/local/ && \
    rm /usr/local/.bun/bin/bunx && \
    ln -s /usr/local/.bun/bin/bun /usr/local/.bun/bin/bunx && \
    chown -R "${ARG_DEVCONTAINER_USER}:${ARG_DEVCONTAINER_USER}" /usr/local/.bun

ENV BUN_INSTALL=/usr/local/.bun
ENV PATH=$BUN_INSTALL/bin:$PATH

RUN bun --version

# Install yq for YAML parsing (required by generate-config.sh)
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq && \
    yq --version

# Switch to the user specified in the globally declared args.
USER ${ARG_DEVCONTAINER_USER}

# -----------------------------------------------------------------------------------------
# -- STAGE 2: ADD CUSTOM WORKSPACE INIT STEPS HERE                                       --
# -----------------------------------------------------------------------------------------
FROM devcontainer_base AS devcontainer_workspace

# Pull in the globally declared args
ARG ARG_DEVCONTAINER_USER

# Switch to the user specified in the globally declared args.
USER ${ARG_DEVCONTAINER_USER}

# Define a directory for the developer workspace files.
WORKDIR /workspace

# Create the devcontainer shared volumes that are being used to override
# existing workspace directories containing only generated files (e.g. node_modules).
RUN mkdir ./node_modules && \
    chown -R "${ARG_DEVCONTAINER_USER}" ./node_modules

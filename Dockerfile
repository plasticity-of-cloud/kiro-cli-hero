FROM ubuntu:24.04

ARG KIRO_CLI_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates nodejs npm \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/kiro-cli@${KIRO_CLI_VERSION}

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

RUN useradd -m -s /bin/bash -u 1000 ubuntu

COPY --chown=ubuntu:ubuntu entrypoint.sh /usr/local/bin/entrypoint.sh

USER ubuntu
WORKDIR /home/ubuntu/workspace

ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/bash"]

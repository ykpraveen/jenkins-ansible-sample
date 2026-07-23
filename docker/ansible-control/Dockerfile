FROM docker:27-cli AS dockercli

FROM python:3.12-slim AS final
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /usr/local/bin/
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-client ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV UV_SYSTEM_PYTHON=1
RUN uv pip install --system --no-cache \
        "ansible-core==2.17.6" \
        "ansible-lint==24.9.2" \
        "yamllint==1.35.1" \
        "molecule==24.9.0" \
        "molecule-plugins[docker]==23.5.3" \
        "docker==7.1.0"

WORKDIR /ansible
CMD ["bash"]

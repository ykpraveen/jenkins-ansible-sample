FROM docker:27-cli AS dockercli

FROM python:3.12-slim AS final
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /usr/local/bin/
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-client ca-certificates curl rsync git openjdk-21-jre-headless && \
    rm -rf /var/lib/apt/lists/*

ENV UV_SYSTEM_PYTHON=1
# Same rationale as docker/ansible-control/Dockerfile: bake collections in at build
# time rather than let molecule/ansible-galaxy fetch them per-run, which fails on
# the corporate TLS-inspecting proxy. See README's corporate network note.
RUN uv pip install --system --no-cache \
        "ansible-core==2.17.6" \
        "ansible-lint==24.9.2" \
        "yamllint==1.35.1" \
        "molecule==24.9.0" \
        "molecule-plugins[docker]==23.5.3" \
        "docker==7.1.0" && \
    ansible-galaxy collection install community.docker ansible.posix --ignore-certs -p /usr/share/ansible/collections

WORKDIR /home/jenkins/agent
CMD ["sleep", "infinity"]

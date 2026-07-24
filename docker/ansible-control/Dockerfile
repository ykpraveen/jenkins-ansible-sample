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

# molecule's docker driver needs community.docker at runtime (for its connection
# plugin), so it's baked in here rather than fetched by molecule's own dependency
# step every test run. --ignore-certs is a deliberate, direct escape hatch for
# building on a TLS-inspecting corporate network — see the README's corporate
# network note. Installed to a HOME-independent path since the container's HOME
# varies by invocation (root by default, /tmp when run with --user).
RUN ansible-galaxy collection install community.docker --ignore-certs -p /usr/share/ansible/collections

WORKDIR /ansible
CMD ["bash"]

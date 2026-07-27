FROM jenkins/jenkins:2.479.2-lts-jdk17

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs

# Optional corporate TLS-inspecting proxy root/intermediate CA(s) — see README's
# corporate network note. corporate-ca/ is empty (just .gitkeep) by default, which
# makes the manual-cert half of this block a no-op; populate it if jenkins-plugin-cli's
# HTTPS fetch below fails with a PKIX path building error. Needs root, unlike the rest
# of this image which runs as the jenkins user.
#
# JENKINS_TRUST_OBSERVED_TLS_CERT is the same style of escape hatch as
# docker_gpg_validate_certs in the Ansible layer: real cert validation by default, one
# opt-in build arg to work around it. Instead of you having to track down and export
# the proxy's actual CA chain, it captures whatever certificate chain the proxy
# presents for the Jenkins update center at build time and trusts it (trust-on-first-
# use) — fine for a local/lab sandbox on a network you control, not a substitute for
# the real corporate-ca/ chain on anything else.
ARG JENKINS_TRUST_OBSERVED_TLS_CERT=false

USER root
COPY corporate-ca/ /usr/local/share/ca-certificates/
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates openssl && \
    rm -rf /var/lib/apt/lists/* && \
    if [ "$JENKINS_TRUST_OBSERVED_TLS_CERT" = "true" ]; then \
        for host in updates.jenkins.io mirrors.updates.jenkins.io; do \
            echo | openssl s_client -connect "$host:443" -servername "$host" -showcerts 2>/dev/null \
                | awk -v host="$host" 'BEGIN{n=0} \
                    /-----BEGIN CERTIFICATE-----/{n++} \
                    /-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ \
                    {print > ("/usr/local/share/ca-certificates/observed-" host "-" n ".crt")}'; \
        done; \
    fi && \
    update-ca-certificates && \
    for cert in /usr/local/share/ca-certificates/*.crt; do \
        [ -e "$cert" ] || continue; \
        keytool -importcert -trustcacerts -noprompt \
            -alias "$(basename "$cert" .crt)" \
            -file "$cert" -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit; \
    done
USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

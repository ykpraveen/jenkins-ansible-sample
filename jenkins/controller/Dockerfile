FROM jenkins/jenkins:2.479.2-lts-jdk17

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs

# Optional corporate TLS-inspecting proxy root/intermediate CA(s) — see README's
# corporate network note. corporate-ca/ is empty (just .gitkeep) by default, which
# makes this whole block a no-op; populate it if jenkins-plugin-cli's HTTPS fetch
# below fails with a PKIX path building error. Needs root, unlike the rest of this
# image which runs as the jenkins user.
USER root
COPY corporate-ca/ /usr/local/share/ca-certificates/
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
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

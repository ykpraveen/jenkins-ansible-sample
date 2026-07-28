pipeline {
    agent { label 'ansible-agent' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        // Manual by default: staging's own post-deploy health check (app_deploy's
        // fail-with-rollback task, Phase 6) already gates a bad build from ever
        // reaching this point, so "automatic" here just means skipping the human
        // approval click, not skipping verification.
        booleanParam(
            name: 'AUTO_PROMOTE',
            defaultValue: false,
            description: 'Skip the manual "Promote to prod?" gate and deploy to prod automatically once staging is healthy.'
        )
    }

    environment {
        REGISTRY   = "registry:5000"
        IMAGE_NAME = "sample-app"
        IMAGE_TAG  = "${env.GIT_COMMIT.take(7)}"
        IMAGE      = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        // The agent's `docker` CLI is just the binary copied out of docker:27-cli
        // (see jenkins/agent/Dockerfile), with no buildx plugin alongside it, so
        // `docker build` falls back to the legacy builder and prints a deprecation
        // warning. The daemon itself supports BuildKit fine — this just opts the
        // classic `docker build` command into using it, without needing buildx.
        DOCKER_BUILDKIT = "1"
    }

    stages {
        stage('Lint') {
            steps {
                sh 'yamllint ansible app .github/workflows'
                withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'ANSIBLE_VAULT_PASSWORD')]) {
                    dir('ansible') {
                        // ansible-lint shells out to `ansible-playbook --syntax-check`,
                        // which loads vault_pass.sh via ansible.cfg — needs the real
                        // credential even though this is only a lint/syntax pass.
                        sh 'ansible-lint bootstrap.yml deploy.yml roles'
                    }
                }
                // DL3008 (pin apt package versions) is ignored: these Dockerfiles
                // apt-get update fresh on every build, so pinning exact Debian package
                // versions here just goes stale and breaks builds later for no real
                // reproducibility gain. No volume mount into this container, so a
                // .hadolint.yaml wouldn't be readable anyway — has to be a CLI flag.
                sh 'docker run --rm -i hadolint/hadolint hadolint --ignore DL3008 - < app/Dockerfile'
                sh 'docker run --rm -i hadolint/hadolint hadolint --ignore DL3008 - < docker/ansible-control/Dockerfile'
                sh 'docker run --rm -i hadolint/hadolint hadolint --ignore DL3008 - < jenkins/agent/Dockerfile'
            }
        }

        stage('Molecule (common role)') {
            steps {
                // molecule launches its own "common-test" container via the agent's
                // bind-mounted docker.sock (DooD, same as the deploy stages' Ansible
                // calls) — a sibling of the agent, not nested inside it, so
                // --destroy=always guarantees cleanup on the host even if an earlier
                // step in the test sequence fails, rather than leaking a container
                // that would otherwise outlive this ephemeral agent.
                dir('ansible/roles/common') {
                    sh 'molecule test --destroy=always'
                }
            }
        }

        stage('Build & Test') {
            steps {
                // app/Dockerfile's "test" stage runs pytest; "final" depends on it via
                // COPY --from=test, so this build fails here if unit tests fail.
                sh "docker build -t ${IMAGE} app"
            }
        }

        stage('Push') {
            steps {
                sh "docker push ${IMAGE}"
            }
        }

        stage('Deploy dev') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'fleet-ssh-key', keyFileVariable: 'FLEET_SSH_KEY'),
                    string(credentialsId: 'ansible-vault-password', variable: 'ANSIBLE_VAULT_PASSWORD')
                ]) {
                    dir('ansible') {
                        // deploy.yml's app_deploy role health-checks the target host itself
                        // and fails the play on a bad response, so a red stage here already
                        // means dev is unhealthy — no separate smoke-test step needed.
                        //
                        // $FLEET_SSH_KEY is deliberately left for the *shell* to expand
                        // (single-quoted), not Groovy — interpolating a credential straight
                        // into the script text via a GString bypasses Jenkins' credential
                        // masking. See https://jenkins.io/redirect/groovy-string-interpolation.
                        sh "ansible-playbook deploy.yml --limit dev -e app_deploy_app_image_tag=${IMAGE_TAG} -e fleet_ssh_private_key_file=" + '$FLEET_SSH_KEY'
                    }
                }
            }
        }

        stage('Deploy staging') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'fleet-ssh-key', keyFileVariable: 'FLEET_SSH_KEY'),
                    string(credentialsId: 'ansible-vault-password', variable: 'ANSIBLE_VAULT_PASSWORD')
                ]) {
                    dir('ansible') {
                        // See the Deploy dev stage's comment on why $FLEET_SSH_KEY is
                        // single-quoted here rather than Groovy-interpolated.
                        sh "ansible-playbook deploy.yml --limit staging -e app_deploy_app_image_tag=${IMAGE_TAG} -e fleet_ssh_private_key_file=" + '$FLEET_SSH_KEY'
                    }
                }
            }
        }

        stage('Promote to prod?') {
            when {
                expression { !params.AUTO_PROMOTE }
            }
            steps {
                input message: "Promote ${IMAGE_TAG} to prod?"
            }
        }

        stage('Deploy prod') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'fleet-ssh-key', keyFileVariable: 'FLEET_SSH_KEY'),
                    string(credentialsId: 'ansible-vault-password', variable: 'ANSIBLE_VAULT_PASSWORD')
                ]) {
                    dir('ansible') {
                        // prod's group_vars sets deploy_serial: 1, so app_deploy rolls
                        // through prod1 then prod2 one at a time, failing fast on prod1.
                        // See the Deploy dev stage's comment on why $FLEET_SSH_KEY is
                        // single-quoted here rather than Groovy-interpolated.
                        sh "ansible-playbook deploy.yml --limit prod -e app_deploy_app_image_tag=${IMAGE_TAG} -e fleet_ssh_private_key_file=" + '$FLEET_SSH_KEY'
                    }
                }
                sh 'curl -sf http://traefik/health'
            }
        }
    }
}

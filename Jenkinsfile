pipeline {
    agent { label 'ansible-agent' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        REGISTRY   = "registry:5000"
        IMAGE_NAME = "sample-app"
        IMAGE_TAG  = "${env.GIT_COMMIT.take(7)}"
        IMAGE      = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
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
                        sh "ansible-playbook deploy.yml --limit dev -e app_deploy_app_image_tag=${IMAGE_TAG} -e fleet_ssh_private_key_file=${FLEET_SSH_KEY}"
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
                        sh "ansible-playbook deploy.yml --limit staging -e app_deploy_app_image_tag=${IMAGE_TAG} -e fleet_ssh_private_key_file=${FLEET_SSH_KEY}"
                    }
                }
            }
        }

        stage('Promote to prod?') {
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
                        sh "ansible-playbook deploy.yml --limit prod -e app_deploy_app_image_tag=${IMAGE_TAG} -e fleet_ssh_private_key_file=${FLEET_SSH_KEY}"
                    }
                }
                sh 'curl -sf http://traefik/health'
            }
        }
    }
}

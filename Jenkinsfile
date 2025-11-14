pipeline {
    agent any

    environment {
        GIT_URL = "git@github.com:shresth963/calculator.git"
        DOCKERHUB = "shresth111"
    }

    parameters {
        string(name: 'BUILD_NUMBER', defaultValue: '1.0', description: 'Tag to use for the Docker image (e.g. 1.0)')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Docker') {
            steps {
                script {
                    // detect docker binary (safer)
                    env.DOCKER_BIN = sh(script: '''#!/bin/bash
                      if command -v docker >/dev/null 2>&1; then
                        command -v docker
                      elif [ -x "/opt/homebrew/bin/docker" ]; then
                        echo /opt/homebrew/bin/docker
                      else
                        echo docker
                      fi
                    ''', returnStdout: true).trim()

                    echo "Using docker binary: ${env.DOCKER_BIN}"

                    // create a temporary docker config dir without credsStore to avoid credential helper calls
                    env.TMP_DOCKER_CONFIG = "${WORKSPACE}/.tmp-docker-config"
                    sh """
                      rm -rf "${env.TMP_DOCKER_CONFIG}"
                      mkdir -p "${env.TMP_DOCKER_CONFIG}"
                      # create minimal config.json that does NOT reference any credential helper
                      cat > "${env.TMP_DOCKER_CONFIG}/config.json" <<'JSON'
                      {
                        "auths": {}
                      }
                      JSON
                    """
                    echo "Created temp DOCKER_CONFIG at ${env.TMP_DOCKER_CONFIG}"
                }
            }
        }

        stage('Build or Detect Image') {
            steps {
                script {
                    def tag = params.BUILD_NUMBER
                    // Use the temporary DOCKER_CONFIG when building so docker won't try credential helpers
                    def dockerCmdPrefix = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"
                    if (fileExists('calculator/Dockerfile')) {
                        echo "Dockerfile found — building image calculator:${tag} from ./calculator"
                        sh "${dockerCmdPrefix} build -t calculator:${tag} ./calculator"
                    } else {
                        echo "No Dockerfile found; checking local images"
                        def imgCheck = sh(script: "${env.DOCKER_BIN} images -q calculator:${tag} || true", returnStdout: true).trim()
                        if (!imgCheck) {
                            def latestCheck = sh(script: "${env.DOCKER_BIN} images -q calculator:latest || true", returnStdout: true).trim()
                            if (!latestCheck) {
                                error("No Dockerfile and no local image 'calculator:${tag}' or 'calculator:latest' found.")
                            } else {
                                sh "${dockerCmdPrefix} tag calculator:latest calculator:${tag}"
                            }
                        }
                    }
                }
            }
        }

        stage('Tag for Docker Hub') {
            steps {
                script {
                    def tag = params.BUILD_NUMBER
                    def dockerCmdPrefix = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"
                    sh "${dockerCmdPrefix} tag calculator:${tag} ${DOCKERHUB}/calculator:${tag}"
                }
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    script {
                        def tag = params.BUILD_NUMBER
                        def dockerCmdPrefix = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"
                        sh """
                          set -e
                          echo "Logging into Docker Hub as \$DH_USER (using temp DOCKER_CONFIG)"
                          echo "\$DH_PASS" | DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} login -u "\$DH_USER" --password-stdin

                          ${dockerCmdPrefix} push ${DOCKERHUB}/calculator:${tag}

                          ${dockerCmdPrefix} tag ${DOCKERHUB}/calculator:${tag} ${DOCKERHUB}/calculator:latest
                          ${dockerCmdPrefix} push ${DOCKERHUB}/calculator:latest

                          # cleanup: logout using the temp config (ignore errors)
                          DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} logout || true
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // cleanup temp config
            sh "rm -rf ${WORKSPACE}/.tmp-docker-config || true"
        }
        success {
            echo "Push finished: https://hub.docker.com/r/${DOCKERHUB}/calculator"
        }
        failure {
            echo "Pipeline failed — check console output for errors."
        }
    }
}

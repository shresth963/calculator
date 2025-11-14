pipeline {
    agent any

    environment {
        GIT_URL  = "git@github.com:shresth963/calculator.git"
        DOCKERHUB = "shresth111"
    }

    parameters {
        string(name: 'BUILD_NUMBER', defaultValue: '1.0', description: 'Tag to use for the Docker image (e.g. 1.0)')
        booleanParam(name: 'USE_PARAM_CREDS', defaultValue: false, description: 'If true, use DOCKER_USER and DOCKER_PASS parameters instead of Jenkins credential docker-hub-creds')
        string(name: 'DOCKER_USER', defaultValue: '', description: 'Docker Hub username (only used if USE_PARAM_CREDS=true)')
        password(name: 'DOCKER_PASS', defaultValue: '', description: 'Docker Hub password or token (only used if USE_PARAM_CREDS=true)')
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out ${GIT_URL}"
                checkout scm
            }
        }

        stage('Prepare Docker') {
            steps {
                script {
                    // Detect docker binary (prefer system docker, fallback to common macos brew path)
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

                    // Create a minimal DOCKER_CONFIG (avoids credential helper errors during build)
                    env.TMP_DOCKER_CONFIG = "${WORKSPACE}/.tmp-docker-config"
                    sh """
rm -rf "${env.TMP_DOCKER_CONFIG}"
mkdir -p "${env.TMP_DOCKER_CONFIG}"
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
                    def dockerCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"

                    if (fileExists('calculator/Dockerfile')) {
                        echo "Dockerfile found — building image calculator:${tag}"
                        sh "${dockerCmd} build -t calculator:${tag} ./calculator"
                    } else {
                        echo "No Dockerfile at calculator/Dockerfile — looking for local image calculator:${tag} or calculator:latest"
                        def img = sh(script: "${env.DOCKER_BIN} images -q calculator:${tag} || true", returnStdout: true).trim()
                        if (!img) {
                            def latest = sh(script: "${env.DOCKER_BIN} images -q calculator:latest || true", returnStdout: true).trim()
                            if (!latest) {
                                error("No Dockerfile and no local image 'calculator:${tag}' or 'calculator:latest' found.")
                            } else {
                                echo "Found calculator:latest — retagging to calculator:${tag}"
                                sh "${dockerCmd} tag calculator:latest calculator:${tag}"
                            }
                        } else {
                            echo "Local image calculator:${tag} exists — skipping build."
                        }
                    }
                }
            }
        }

        stage('Tag for Docker Hub') {
            steps {
                script {
                    def tag = params.BUILD_NUMBER
                    def dockerCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"
                    echo "Tagging calculator:${tag} -> ${DOCKERHUB}/calculator:${tag}"
                    sh "${dockerCmd} tag calculator:${tag} ${DOCKERHUB}/calculator:${tag}"
                }
            }
        }

        stage('Docker Login & Push') {
            steps {
                script {
                    def tag = params.BUILD_NUMBER
                    def dockerCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"

                    if (params.USE_PARAM_CREDS && params.DOCKER_USER?.trim()) {
                        echo "Using credentials from job parameters (USE_PARAM_CREDS=true)."
                        sh """
set -e
echo "${params.DOCKER_PASS}" | DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} login -u "${params.DOCKER_USER}" --password-stdin
${dockerCmd} push ${DOCKERHUB}/calculator:${tag}
${dockerCmd} tag ${DOCKERHUB}/calculator:${tag} ${DOCKERHUB}/calculator:latest
${dockerCmd} push ${DOCKERHUB}/calculator:latest
DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} logout || true
"""
                    } else {
                        echo "Using Jenkins credential id 'docker-hub-creds' (recommended)."
                        withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                            sh """
set -e
echo "$DH_PASS" | DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} login -u "$DH_USER" --password-stdin
${dockerCmd} push ${DOCKERHUB}/calculator:${tag}
${dockerCmd} tag ${DOCKERHUB}/calculator:${tag} ${DOCKERHUB}/calculator:latest
${dockerCmd} push ${DOCKERHUB}/calculator:latest
DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} logout || true
"""
                        }
                    }
                }
            }
        }
    }

    post {
        always {
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

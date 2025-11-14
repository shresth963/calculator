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
                echo "Checking out source code from ${GIT_URL}"
                checkout scm
            }
        }

        stage('Prepare Docker') {
            steps {
                script {
                    // Safer way to detect docker binary: use a small shell script and trim output
                    def dockerBin = sh(
                        script: '''#!/bin/bash
                        set -euo pipefail
                        if command -v docker >/dev/null 2>&1; then
                          command -v docker
                        else
                          echo /opt/homebrew/bin/docker
                        fi
                        ''',
                        returnStdout: true
                    ).trim()

                    // assign into environment var for later stages
                    env.DOCKER_BIN = dockerBin
                    echo "Using docker binary: ${env.DOCKER_BIN}"
                }
            }
        }

        stage('Build or Detect Image') {
            steps {
                script {
                    def tag = params.BUILD_NUMBER
                    def dockerfileExists = fileExists('calculator/Dockerfile')
                    if (dockerfileExists) {
                        echo "Dockerfile found — building image calculator:${tag} from ./calculator"
                        sh """${env.DOCKER_BIN} build -t calculator:${tag} ./calculator"""
                    } else {
                        echo "No Dockerfile at calculator/Dockerfile — will look for an existing local image named 'calculator:${tag}' or 'calculator:latest'"
                        def imgCheck = sh(script: "${env.DOCKER_BIN} images -q calculator:${tag} || true", returnStdout: true).trim()
                        if (!imgCheck) {
                            echo "No local image calculator:${tag} found. Attempting to find calculator:latest..."
                            def latestCheck = sh(script: "${env.DOCKER_BIN} images -q calculator:latest || true", returnStdout: true).trim()
                            if (!latestCheck) {
                                error("No Dockerfile and no local image 'calculator:${tag}' or 'calculator:latest' found. Add Dockerfile or pre-build the image.")
                            } else {
                                echo "Found calculator:latest — will retag it to calculator:${tag}"
                                sh """${env.DOCKER_BIN} tag calculator:latest calculator:${tag}"""
                            }
                        } else {
                            echo "Local image calculator:${tag} already exists — skipping build."
                        }
                    }
                }
            }
        }

        stage('Tag for Docker Hub') {
            steps {
                script {
                    def tag = params.BUILD_NUMBER
                    echo "Tagging local image calculator:${tag} -> ${DOCKERHUB}/calculator:${tag}"
                    sh """${env.DOCKER_BIN} tag calculator:${tag} ${DOCKERHUB}/calculator:${tag}"""
                }
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    script {
                        def tag = params.BUILD_NUMBER
                        sh '''
                            set -e
                            echo "Logging into Docker Hub as $DH_USER"
                            echo "$DH_PASS" | ${DOCKER_BIN} login -u "$DH_USER" --password-stdin

                            echo "Pushing ${DOCKERHUB}/calculator:${tag}"
                            ${DOCKER_BIN} push ${DOCKERHUB}/calculator:${tag}

                            echo "Also tagging and pushing latest"
                            ${DOCKER_BIN} tag ${DOCKERHUB}/calculator:${tag} ${DOCKERHUB}/calculator:latest
                            ${DOCKER_BIN} push ${DOCKERHUB}/calculator:latest

                            ${DOCKER_BIN} logout || true
                        '''.replace('${DOCKER_BIN}', env.DOCKER_BIN).replace('${DOCKERHUB}', env.DOCKERHUB)
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Push finished: https://hub.docker.com/r/${DOCKERHUB}/calculator"
        }
        failure {
            echo "Pipeline failed — check console output for errors."
        }
    }
}

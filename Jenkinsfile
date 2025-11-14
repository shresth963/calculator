pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "shresth111"
        DOCKERHUB_REPO = "calculator"
        TAG = "latest"
        DOCKER_BIN = "/opt/homebrew/bin/docker"
        DOCKERHUB_CREDS = "docker-hub-creds"
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh """
                    ${DOCKER_BIN} build -t ${DOCKERHUB_REPO}:${TAG} ./calculator
                """
            }
        }

        stage('Tag Image') {
            steps {
                echo "Tagging image for Docker Hub..."
                sh """
                    ${DOCKER_BIN} tag ${DOCKERHUB_REPO}:${TAG} ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG}
                """
            }
        }

        stage('Login & Push to Docker Hub') {
            steps {
                echo "Pushing image to Docker Hub..."
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDS}",
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh """
                        echo "$PASS" | ${DOCKER_BIN} login -u "$USER" --password-stdin
                        
                        ${DOCKER_BIN} push ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG}

                        ${DOCKER_BIN} logout
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Image Pushed Successfully: https://hub.docker.com/r/${DOCKERHUB_USER}/${DOCKERHUB_REPO}"
        }
        failure {
            echo "Pipeline Failed — check errors."
        }
    }
}

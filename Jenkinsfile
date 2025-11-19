pipeline {
  agent any
  environment {
    IMAGE_NAME = "shresth111/calculator"
    IMAGE_TAG  = "59"
    // Set DOCKER_BIN in Jenkins Global env if docker is in a non-standard location, e.g. /opt/homebrew/bin/docker
    DOCKER_BIN = "${env.DOCKER_BIN ?: 'docker'}"
  }
  stages {
    stage('Pre-check') {
      steps {
        script {
          sh """
            if ! command -v ${DOCKER_BIN} >/dev/null 2>&1; then
              echo "ERROR: docker CLI not found. Expected at: ${DOCKER_BIN}"
              echo "Possible fixes:"
              echo " - Install Docker (e.g. Docker Desktop on macOS)"
              echo " - Ensure the Jenkins agent user can access docker"
              echo " - Set DOCKER_BIN env var in Jenkins global config to the exact docker path"
              exit 127
            fi

            # Check docker daemon
            ${DOCKER_BIN} info >/dev/null 2>&1 || {
              echo "ERROR: docker daemon not running or not accessible by this user."
              echo "Start Docker Desktop or ensure dockerd is running."
              ${DOCKER_BIN} version || true
              exit 127
            }
          """
        }
      }
    }

    stage('Build Image') {
      steps {
        sh "${DOCKER_BIN} build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
      }
    }

    stage('Push Image') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh """
              echo "$DOCKER_PASS" | ${DOCKER_BIN} login -u "$DOCKER_USER" --password-stdin
              ${DOCKER_BIN} push ${IMAGE_NAME}:${IMAGE_TAG}
            """
          }
        }
      }
    }
  }

  post {
    success { echo "Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}" }
    failure  { echo "Pipeline failed. See errors above for docker availability or credential issues." }
  }
}

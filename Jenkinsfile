pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag to push (e.g. 1.0, latest)')
  }

  environment {
    DOCKERHUB_REPO = "shresth111/calculator"
    CRED_ID = "docker-hub-creds"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Detect Docker') {
      steps {
        script {
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
          sh "${env.DOCKER_BIN} --version || true"
        }
      }
    }

    stage('Prepare DOCKER_CONFIG') {
      steps {
        script {
          env.TMP_DOCKER_CONFIG = "${WORKSPACE}/.tmp-docker-config"
          sh """
            rm -rf "${env.TMP_DOCKER_CONFIG}"
            mkdir -p "${env.TMP_DOCKER_CONFIG}"
            cat > "${env.TMP_DOCKER_CONFIG}/config.json" <<'JSON'
{ "auths": {} }
JSON
          """
          echo "Temporary DOCKER_CONFIG created at ${env.TMP_DOCKER_CONFIG}"
        }
      }
    }

    stage('Build Image') {
      steps {
        script {
          def tag = params.IMAGE_TAG
          def buildCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"
          if (!fileExists('calculator/Dockerfile')) {
            error "calculator/Dockerfile not found in workspace. Ensure repository layout is correct."
          }
          echo "Building ${DOCKERHUB_REPO}:${tag} ..."
          sh "${buildCmd} build -t ${DOCKERHUB_REPO}:${tag} ./calculator"
        }
      }
    }

    stage('Login & Push') {
      steps {
        script {
          def tag = params.IMAGE_TAG
          def dockerCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"

          // Use Jenkins credential (username + password/token)
          withCredentials([usernamePassword(credentialsId: "${CRED_ID}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
            sh """
              set -e
              echo "Logging into Docker Hub as \$DH_USER (using temporary DOCKER_CONFIG)..."
              echo "\$DH_PASS" | DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} login -u "\$DH_USER" --password-stdin

              echo "Pushing ${DOCKERHUB_REPO}:${tag} ..."
              ${dockerCmd} push ${DOCKERHUB_REPO}:${tag}

              echo "Also tagging and pushing 'latest' (optional)..."
              ${dockerCmd} tag ${DOCKERHUB_REPO}:${tag} ${DOCKERHUB_REPO}:latest || true
              ${dockerCmd} push ${DOCKERHUB_REPO}:latest || true

              echo "Docker push done."
              DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} logout || true
            """
          }
        }
      }
    }
  }

  post {
    always {
      sh "rm -rf ${WORKSPACE}/.tmp-docker-config || true"
      echo "Cleaned up temporary Docker config."
    }
    success {
      echo "SUCCESS: Image pushed -> https://hub.docker.com/r/${DOCKERHUB_REPO.split('/')[0]}/${DOCKERHUB_REPO.split('/')[1]}:${params.IMAGE_TAG}"
    }
    failure {
      echo "FAILURE: check console output above for errors."
    }
  }
}

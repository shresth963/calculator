pipeline {
  agent any

  environment {
    DOCKERHUB_USER = "shresth111"
    DOCKERHUB_REPO = "calculator"
    TAG = "latest"
    CRED_ID = "docker-hub-creds"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Detect Docker') {
      steps {
        script {
          env.DOCKER_BIN = sh(script: '''
            #!/bin/bash
            set -e
            if command -v docker >/dev/null 2>&1; then
              command -v docker
            elif [ -x "/opt/homebrew/bin/docker" ]; then
              echo /opt/homebrew/bin/docker
            else
              echo docker
            fi
          ''', returnStdout: true).trim()
          echo "Docker binary: ${env.DOCKER_BIN}"
          // quick check (non-failing): show version and info for diagnostics
          sh "echo '--- docker version ---'; ${env.DOCKER_BIN} --version || true"
          sh "echo '--- docker info (may fail if daemon not running) ---'; ${env.DOCKER_BIN} info || true"
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
          echo "Created temporary DOCKER_CONFIG at ${env.TMP_DOCKER_CONFIG}"
        }
      }
    }

    stage('Build Image') {
      steps {
        script {
          def dockerCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"
          if (!fileExists('calculator/Dockerfile')) {
            error "No calculator/Dockerfile found in workspace. Aborting."
          }
          echo "Building ${DOCKERHUB_REPO}:${TAG}"
          sh "${dockerCmd} build -t ${DOCKERHUB_REPO}:${TAG} ./calculator"
        }
      }
    }

    stage('Tag Image') {
      steps {
        script {
          def dockerCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"
          sh "${dockerCmd} tag ${DOCKERHUB_REPO}:${TAG} ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG}"
          echo "Tagged as ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG}"
        }
      }
    }

    stage('Login & Push') {
      steps {
        script {
          def dockerCmd = "DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN}"

          // Check credential existence first (graceful diagnostic)
          def credExists = false
          try {
            withCredentials([usernamePassword(credentialsId: "${CRED_ID}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
              // if we get here, credential exists — but do not echo secrets
              credExists = true
              echo "Found Jenkins credential '${CRED_ID}' and will use it to login."
              // perform login & push
              sh """
                set -e
                echo "\$DH_PASS" | DOCKER_CONFIG=${env.TMP_DOCKER_CONFIG} ${env.DOCKER_BIN} login -u "\$DH_USER" --password-stdin
                ${dockerCmd} push ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG}
                ${dockerCmd} logout || true
              """
            }
          } catch (err) {
            // credential missing or failed; provide explicit guidance
            echo "ERROR: Jenkins credential '${CRED_ID}' not found or could not be accessed."
            echo "Action: Create credential with: Kind='Username with password', Username='${DOCKERHUB_USER}', ID='${CRED_ID}', Password=your Docker Hub token or password."
            echo "Or run the job with parameter-based auth (not recommended)."
            error "Missing Jenkins credential '${CRED_ID}'. See above instructions."
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
      echo "SUCCESS: image pushed to ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG}"
    }
    failure {
      echo "Pipeline failed — read previous messages for the exact failure cause."
    }
  }
}

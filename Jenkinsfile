pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag to push (e.g. 1.0 or latest)')
    // Optional quick-test fallback (less secure) — only use for temporary testing
    booleanParam(name: 'USE_PARAM_CREDS', defaultValue: false, description: 'If true, use DOCKER_USER/DOCKER_PASS parameters to login (temporary)')
    string(name: 'DOCKER_USER', defaultValue: 'shresth111', description: 'Docker Hub user (used only if USE_PARAM_CREDS=true)')
    password(name: 'DOCKER_PASS', defaultValue: '', description: 'Docker Hub password/token (used only if USE_PARAM_CREDS=true)')
    string(name: 'DOCKER_CREDENTIAL_ID', defaultValue: '', description: 'Optional Jenkins credential ID for Docker Hub login/push')
  }

  environment {
    IMAGE_NAME = "calculator"
    DOCKERHUB_REPO = "${params.DOCKER_USER}/${env.IMAGE_NAME}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Detect docker') {
      steps {
        script {
          // Try common paths and `command -v docker`
          def paths = ['/opt/homebrew/bin/docker', '/usr/local/bin/docker', '/usr/bin/docker', 'docker']
          env.DOCKER_BIN = ''
          for (p in paths) {
            def out = sh(script: "command -v ${p} >/dev/null 2>&1 && echo ${p} || true", returnStdout: true).trim()
            if (out) { env.DOCKER_BIN = out; break }
          }
          if (!env.DOCKER_BIN) {
            env.DOCKER_BIN = sh(script: "command -v docker || true", returnStdout: true).trim()
          }
          if (!env.DOCKER_BIN) {
            error """docker CLI not found on this node.
Fixes:
  • Start Docker Desktop on the machine running this agent, or
  • Install Docker so 'docker' is available in PATH, or
  • Add the docker folder (e.g. /opt/homebrew/bin) to the node PATH in Jenkins node config.
"""
          }
          echo "Using docker binary: ${env.DOCKER_BIN}"
          sh "${env.DOCKER_BIN} --version || true"
        }
      }
    }

    stage('Build image') {
      steps {
        script {
          if (!fileExists('calculator/Dockerfile')) {
            error "calculator/Dockerfile not found in workspace — ensure repository layout is correct"
          }
          sh "${env.DOCKER_BIN} build -t ${env.IMAGE_NAME}:${params.IMAGE_TAG} ./calculator"
        }
      }
    }

    stage('Tag image for Docker Hub') {
      steps {
        script {
          // Tag using DOCKER_USER (either from param or from creds later)
          sh "${env.DOCKER_BIN} tag ${env.IMAGE_NAME}:${params.IMAGE_TAG} ${params.DOCKER_USER}/${env.IMAGE_NAME}:${params.IMAGE_TAG}"
        }
      }
    }

    stage('Login & Push') {
      steps {
        script {
          def paramDockerPass = params.DOCKER_PASS ? params.DOCKER_PASS.getPlainText() : ''

          // Helper to push using plain parameters (not recommended for long-term use)
          def pushWithParams = {
            if (!paramDockerPass?.trim()) {
              error "DOCKER_PASS parameter is empty; cannot push with parameters."
            }
            echo "Using parameter-based credentials (temporary fallback)."
            sh """
              set -e
              echo "${paramDockerPass}" | ${env.DOCKER_BIN} login -u "${params.DOCKER_USER}" --password-stdin
              ${env.DOCKER_BIN} push ${params.DOCKER_USER}/${env.IMAGE_NAME}:${params.IMAGE_TAG}
              ${env.DOCKER_BIN} logout || true
            """
          }

          if (params.USE_PARAM_CREDS) {
            pushWithParams()
            return
          }

          if (params.DOCKER_CREDENTIAL_ID?.trim()) {
            try {
              echo "Attempting secure login using Jenkins credential id '${params.DOCKER_CREDENTIAL_ID}'..."
              withCredentials([usernamePassword(credentialsId: params.DOCKER_CREDENTIAL_ID, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                sh """
                  set -e
                  echo "\$DH_PASS" | ${env.DOCKER_BIN} login -u "\$DH_USER" --password-stdin
                  ${env.DOCKER_BIN} push \$DH_USER/${env.IMAGE_NAME}:${params.IMAGE_TAG}
                  ${env.DOCKER_BIN} logout || true
                """
              }
              return
            } catch (Exception credEx) {
              echo "Warning: credential '${params.DOCKER_CREDENTIAL_ID}' not usable (${credEx.message})."
              if (!paramDockerPass?.trim()) {
                throw credEx
              }
              echo "Falling back to DOCKER_USER/DOCKER_PASS parameters."
            }
          }

          if (paramDockerPass?.trim()) {
            pushWithParams()
          } else {
            error """
No Docker Hub credentials provided.
Either:
  • Set DOCKER_CREDENTIAL_ID to a valid Jenkins credential, or
  • Enable USE_PARAM_CREDS and provide DOCKER_USER/DOCKER_PASS.
"""
          }
        }
      }
    }
  }

  post {
    always {
      sh 'echo "Cleaning up (docker logout)"; true'
    }
    success {
      echo "SUCCESS: pushed -> https://hub.docker.com/r/${params.DOCKER_USER}/${env.IMAGE_NAME}:${params.IMAGE_TAG}"
    }
    failure {
      echo "FAILED: check the console for errors above."
    }
  }
}

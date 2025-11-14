pipeline {
  agent any

  environment {
    IMAGE_NAME = "calculator"
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'latest'}"
    IMAGE_REPO = "shresth111/calculator" // change if you want a different repo
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
          def candidates = ['/opt/homebrew/bin/docker', '/usr/local/bin/docker', '/usr/bin/docker', 'docker']
          env.DOCKER_BIN = ''
          for (path in candidates) {
            def found = sh(script: "command -v ${path} >/dev/null 2>&1 && echo ${path} || true", returnStdout: true).trim()
            if (found) {
              env.DOCKER_BIN = found
              break
            }
          }
          if (!env.DOCKER_BIN) {
            error "docker CLI not found on this agent. Install/enable Docker Desktop or add docker to PATH."
          }
          echo "Using docker binary: ${env.DOCKER_BIN}"
          sh "${env.DOCKER_BIN} --version || true"
        }
      }
    }

    stage('Build Image') {
      steps {
        script {
          def contextDir = fileExists('calculator/Dockerfile') ? 'calculator' : '.'
          sh """
            set -e
            cd ${contextDir}
            ${env.DOCKER_BIN} build -t ${env.IMAGE_NAME}:${env.IMAGE_TAG} .
          """
        }
      }
    }

    stage('Push Image') {
      steps {
        script {
          def targetRepo = env.IMAGE_REPO?.trim() ? env.IMAGE_REPO : env.IMAGE_NAME
          def pushCmd = """
            set -e
            ${env.DOCKER_BIN} tag ${env.IMAGE_NAME}:${env.IMAGE_TAG} ${targetRepo}:${env.IMAGE_TAG}
            ${env.DOCKER_BIN} push ${targetRepo}:${env.IMAGE_TAG}
          """

          if (env.DOCKER_CREDENTIAL_ID?.trim()) {
            withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIAL_ID, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
              sh """
                set -e
                echo "\$DH_PASS" | ${env.DOCKER_BIN} login -u "\$DH_USER" --password-stdin
                ${pushCmd}
                ${env.DOCKER_BIN} logout || true
              """
            }
          } else {
            sh pushCmd
          }
        }
      }
    }
  }

  post {
    success {
      script {
        def targetRepo = env.IMAGE_REPO?.trim() ? env.IMAGE_REPO : env.IMAGE_NAME
        echo "SUCCESS: ${env.IMAGE_NAME}:${env.IMAGE_TAG} tagged and pushed as ${targetRepo}:${env.IMAGE_TAG}."
      }
    }
    failure {
      echo "FAILED: check the stage logs for details."
    }
  }
}


pipeline {
  agent any

  environment {
    IMAGE_NAME = "calculator"
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'latest'}"
    IMAGE_REPO = "shresth111/calculator"      // change if you want a different repo
    DOCKER_CREDENTIAL_ID = 'dockerhub-creds' // create this in Jenkins credentials (username + password/token)
  }

  options {
    timeout(time: 30, unit: 'MINUTES')
    ansiColor('xterm')
    timestamps()
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
          echo "Using build context: ${contextDir}"
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
          if (!env.DOCKER_CREDENTIAL_ID?.trim()) {
            error "DOCKER_CREDENTIAL_ID is not set. Create Jenkins credentials and set DOCKER_CREDENTIAL_ID."
          }

          def targetRepo = env.IMAGE_REPO?.trim() ? env.IMAGE_REPO : env.IMAGE_NAME
          def imageWithTag = "${targetRepo}:${env.IMAGE_TAG}"

          // Tag locally
          sh "${env.DOCKER_BIN} tag ${env.IMAGE_NAME}:${env.IMAGE_TAG} ${imageWithTag}"

          // Login, push (with retries), logout — using Jenkins credentials
          withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIAL_ID, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
            sh """
              set -e
              echo "Logging in to Docker registry as \$DH_USER"
              echo "\$DH_PASS" | ${env.DOCKER_BIN} login -u "\$DH_USER" --password-stdin || { echo "docker login failed"; exit 1; }

              attempt=0
              max=3
              until [ \$attempt -ge \$max ]
              do
                ${env.DOCKER_BIN} push ${imageWithTag} && break
                attempt=\$((attempt+1))
                echo "Push attempt \$attempt failed — retrying in 3s..."
                sleep 3
              done

              # if last push still failed, make the script fail
              if [ \$attempt -ge \$max ]; then
                echo "Push failed after \$max attempts"
                exit 1
              fi

              ${env.DOCKER_BIN} logout || true
            """
          }
        }
      }
    }
  }

  post {
    success {
      script {
        def targetRepo = env.IMAGE_REPO?.trim() ? env.IMAGE_REPO : env.IMAGE_NAME
        echo "SUCCESS: ${env.IMAGE_NAME}:${env.IMAGE_TAG} pushed as ${targetRepo}:${env.IMAGE_TAG}"
      }
    }
    failure {
      echo "FAILED: check the stage logs for details."
    }
  }
}

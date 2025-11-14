pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag')
    string(name: 'DOCKER_USER', defaultValue: 'shresth111', description: 'Docker Hub user')
    password(name: 'DOCKER_PASS', defaultValue: '', description: 'Docker Hub password or access token (temporary)')
  }

  environment {
    IMAGE_NAME = "calculator"
    DOCKERHUB_REPO = "${params.DOCKER_USER}/${env.IMAGE_NAME}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build image') {
      steps {
        script {
          if (!fileExists('calculator/Dockerfile')) {
            error "calculator/Dockerfile not found in workspace"
          }
          sh "docker build -t ${env.IMAGE_NAME}:${params.IMAGE_TAG} ./calculator"
        }
      }
    }

    stage('Tag & Login') {
      steps {
        script {
          sh "docker tag ${env.IMAGE_NAME}:${params.IMAGE_TAG} ${DOCKERHUB_REPO}:${params.IMAGE_TAG}"
          // login using provided parameters (less secure, only for now)
          sh '''
            set -e
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            echo "Logged into Docker Hub as $DOCKER_USER"
          '''
        }
      }
    }

    stage('Push') {
      steps {
        sh "docker push ${DOCKERHUB_REPO}:${params.IMAGE_TAG}"
      }
    }
  }

  post {
    always { sh 'docker logout || true' }
    success { echo "Pushed ${DOCKERHUB_REPO}:${params.IMAGE_TAG}" }
    failure { echo "Push failed — check console for the error" }
  }
}

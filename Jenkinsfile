pipeline {
  agent any
  environment {
    IMAGE_NAME = "shresth111/calculator"
    IMAGE_TAG  = "59"
  }
  stages {
    stage('Build Image') {
      steps {
        sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
      }
    }

    stage('Push Image') {
      steps {
        // Option 1: use docker.withRegistry (preferred if docker pipeline plugin is installed)
        script {
          try {
            docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
              docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
            }
          } catch (err) {
            // fallback: manual docker login + push
            withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                             usernameVariable: 'DOCKER_USER',
                                             passwordVariable: 'DOCKER_PASS')]) {
              sh '''
                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                docker push ${IMAGE_NAME}:${IMAGE_TAG}
              '''
            }
          }
        }
      }
    }
  }
  post {
    success { echo "Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}" }
    failure { echo "Push failed — check credentials and repository access." }
  }
}

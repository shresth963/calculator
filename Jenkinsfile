pipeline {
    agent any

   environment {
        GIT_URL = "git@github.com:shresth963/calculator.git"
    }
   parameters {
        string(name: 'BUILD_NUMBER', defaultValue: '1', description: 'Build number for the Docker image')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out source code"
                    sh "git clone ${GIT_URL}"
                }
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    echo "Building Docker image for Calculator App"
                    sh "cd calculator && docker build -t calculator-app:${BUILD_NUMBER} ."
                }
            }
        }
    }
}


pipeline {
    agent any

   parameters {
        string(name: 'BUILD_NUMBER', defaultValue: '1', description: 'Build number for the Docker image')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out source code"
                    checkout scm
                }
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    echo "Building Docker image for Calculator App"
                    sh "whoami && pwd"
                    sh "docker build -t calculator-app:${BUILD_NUMBER} ."
                }
            }
        }
    }
}


pipeline {
    agent any

   parameters {
        string(name: 'BUILD_NUMBER', defaultValue: '1', description: 'Build number for the Docker image')
    }

    stages {
        stage('Docker Build') {
            steps {
                script {
                    echo "Building Docker image for Calculator App"
                    sh "whoami"
                    sh "docker build -t calculator-app:${BUILD_NUMBER} ."
                }
            }
        }
    }
}


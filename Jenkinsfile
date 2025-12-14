pipeline {
    agent any

    environment {
        APP_SERVER = "ubuntu@172.31.18.35"
        APP_NAME   = "calculator"
        APP_PORT   = "3000"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy on EC2') {
            steps {
                sh '''
                ssh ${APP_SERVER} "
                    docker rm -f ${APP_NAME} || true
                    docker rmi ${APP_NAME} || true

                    rm -rf ${APP_NAME}
                    git clone https://github.com/shresth963/calculator.git ${APP_NAME}
                    cd ${APP_NAME}

                    docker build -t ${APP_NAME}:latest .
                    docker run -d --name ${APP_NAME} -p ${APP_PORT}:${APP_PORT} ${APP_NAME}:latest
                "
                '''
            }
        }
    }
}

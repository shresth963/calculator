pipeline {
    agent any

    environment {
        APP_SERVER = "ubuntu@172.31.18.35"
        APP_NAME   = "calculator"
        HOST_PORT  = "3000"   // Browser se access ke liye
        CONTAINER_PORT = "5000" // Gunicorn port
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
                    # Remove old container
                    docker rm -f ${APP_NAME} || true
                    docker rmi ${APP_NAME} || true

                    # Clone fresh repo
                    rm -rf ${APP_NAME}
                    git clone https://github.com/shresth963/calculator.git ${APP_NAME}
                    cd ${APP_NAME}

                    # Build and run Docker container
                    docker build -t ${APP_NAME}:latest .
                    docker run -d --name ${APP_NAME} -p ${HOST_PORT}:${CONTAINER_PORT} ${APP_NAME}:latest

                    # Deploy NGINX config from repo
                    sudo cp calculator.nginx.conf /etc/nginx/sites-available/${APP_NAME}
                    sudo ln -sf /etc/nginx/sites-available/${APP_NAME} /etc/nginx/sites-enabled/
                    sudo nginx -t
                    sudo systemctl restart nginx
                "
                '''
            }
        }
    }
}

pipeline {
    agent any

    environment {
        APP_SERVER = "ubuntu@172.31.18.35"
        APP_NAME   = "calculator"
        APP_PORT   = "3000"   // Docker container port
        NGINX_PORT = "80"     // Public port for NGINX
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
                    echo '=== Stopping & removing old container ==='
                    docker rm -f ${APP_NAME} || true
                    docker rmi ${APP_NAME}:latest || true

                    echo '=== Removing old code ==='
                    rm -rf ${APP_NAME}
                    git clone https://github.com/shresth963/calculator.git ${APP_NAME}
                    cd ${APP_NAME}

                    echo '=== Building Docker image ==='
                    docker build -t ${APP_NAME}:latest .

                    echo '=== Running Docker container ==='
                    docker run -d --name ${APP_NAME} -p ${APP_PORT}:${APP_PORT} ${APP_NAME}:latest

                    echo '=== Setting up NGINX ==='
                    sudo cp calculator.nginx.conf /etc/nginx/sites-available/${APP_NAME}
                    sudo ln -sf /etc/nginx/sites-available/${APP_NAME} /etc/nginx/sites-enabled/
                    sudo nginx -t
                    sudo systemctl restart nginx

                    echo '=== Deployment complete ==='
                "
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! App should be live at http://${APP_SERVER}"
        }
        failure {
            echo "❌ Deployment failed. Check Jenkins console for errors."
        }
    }
}

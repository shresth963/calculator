pipeline {
    agent any

    environment {
        VENV = "${WORKSPACE}/venv"
        NODE_OPTIONS = "--openssl-legacy-provider"
        PYTHON = "python3"
    }

    options {
        timestamps()
        ansiColor('xterm')
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Install Backend Dependencies') {
            steps {
                sh '''
                set -euxo pipefail
                ${PYTHON} -m venv "${VENV}"
                "${VENV}/bin/python" -m pip install --upgrade pip setuptools wheel
                "${VENV}/bin/pip" install -r backend/requirements.txt
                '''
            }
        }

        stage('Backend Lint & Tests') {
            steps {
                sh '''
                set -euxo pipefail
                "${VENV}/bin/flake8" backend/app.py
                "${VENV}/bin/pytest" backend/tests.py
                '''
            }
        }

        stage('Install Frontend Dependencies') {
            steps {
                sh '''
                set -euxo pipefail
                cd frontend
                if command -v corepack >/dev/null 2>&1; then
                  corepack enable
                fi
                if ! command -v yarn >/dev/null 2>&1; then
                  npm install -g yarn
                fi
                yarn install --frozen-lockfile
                '''
            }
        }

        stage('Frontend Tests') {
            steps {
                withEnv(['CI=true']) {
                    sh '''
                    set -euxo pipefail
                    cd frontend
                    yarn test --watchAll=false
                    '''
                }
            }
        }

        stage('Build Frontend') {
            steps {
                sh '''
                set -euxo pipefail
                cd frontend
                yarn build
                '''
                sh '''
                set -euxo pipefail
                rm -rf backend/client
                mkdir -p backend/client
                cp -R frontend/build/. backend/client/
                '''
            }
        }

        stage('Docker Build') {
            when {
                expression {
                    return sh(script: "command -v docker >/dev/null 2>&1", returnStatus: true) == 0
                }
            }
            steps {
                sh '''
                set -euxo pipefail
                docker build -t calculator-app:${BUILD_NUMBER} .
                '''
            }
        }
    }

    post {
        always {
            sh '''
            set +e
            rm -rf "${VENV}"
            '''
        }
        success {
            echo 'Build pipeline completed successfully.'
        }
        failure {
            echo 'Build pipeline failed. Check stage logs for details.'
        }
    }
}


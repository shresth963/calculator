pipeline {
    agent any

    environment {
        VENV = "${WORKSPACE}/venv"
        NODE_OPTIONS = "--openssl-legacy-provider"
        PYTHON = "python3"
        PATH = "${WORKSPACE}/venv/bin:${PATH}"
        YARN_CACHE_FOLDER = "${WORKSPACE}/.yarn-cache"
    }

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        ansiColor('xterm')
        timestamps()
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
                dir('frontend') {
                    sh '''
                    set -euxo pipefail
                    node --version
                    if command -v corepack >/dev/null 2>&1; then
                      corepack enable
                      corepack prepare yarn@1.22.22 --activate
                    elif ! command -v yarn >/dev/null 2>&1; then
                      npm install -g yarn
                    fi
                    yarn install --frozen-lockfile
                    '''
                }
            }
        }

        stage('Frontend Tests') {
            steps {
                dir('frontend') {
                    withEnv(["CI=true", "NODE_OPTIONS=${NODE_OPTIONS}"]) {
                        sh '''
                        set -euxo pipefail
                        yarn test --watchAll=false
                        '''
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    withEnv(["NODE_OPTIONS=${NODE_OPTIONS}"]) {
                        sh '''
                        set -euxo pipefail
                        yarn build
                        '''
                    }
                }
                sh '''
                set -euxo pipefail
                rm -rf backend/client
                mkdir -p backend/client
                rsync -a frontend/build/ backend/client/
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
            rm -rf frontend/node_modules frontend/build
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


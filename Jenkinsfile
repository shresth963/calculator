pipeline {
    agent any

    environment {
        VENV = "${WORKSPACE}/venv"
        NODE_OPTIONS = "--openssl-legacy-provider"
        PYTHON = "python3"
        PATH = "${WORKSPACE}/venv/bin:${PATH}"
        YARN_CACHE_FOLDER = "${WORKSPACE}/.yarn-cache"
    }

    stages {


        stage('Docker Build') {
            when {
                expression {
                    return sh(script: "command -v docker >/dev/null 2>&1", returnStatus: true) == 0
                }
            }
            steps {
                ansiColor('xterm') {
                    sh '''
                    set -euxo pipefail
                    docker build -t calculator-app:${BUILD_NUMBER} .
                    '''
                }
            }
        }
    }
    }


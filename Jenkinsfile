pipeline {
    agent any

    environment {
        GIT_URL = "git@github.com:shresth963/calculator.git"
        DOCKERHUB = "shresth111"
    }

    parameters {
        string(name: 'BUILD_NUMBER', defaultValue: '1.0', description: 'Tag to use for the Docker image (e.g. 1.0)')
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out source code from ${GIT_URL}"
                // If job is configured with repository, checkout scm will work.
                // Otherwise uncomment the git clone line and ensure the agent has SSH access to GitHub.
                checkout scm
                // sh "git clone ${GIT_URL}"
            }
        }

        stage('Prepare Docker') {
            steps {
                script {
                    // find docker binary (try system docker, then Homebrew path)
                    env.DOCKER_BIN = sh(script: "command -v docker || echo /_

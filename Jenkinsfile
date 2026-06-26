pipeline {
    agent { label params.AGENT }

    parameters {
        choice(name: 'AGENT', choices: ['garcia-fidji', 'gaby-fidji', 'fidji-cregnier', 'prod-fidji', 'fidji'], description: 'Which node to run the job on')
    }

    options {
        skipDefaultCheckout(true)
        parallelsAlwaysFailFast()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    environment {
        CONDA_ENV = "class4_${env.BRANCH_NAME}"
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
                script {
                    def result = sh (script: "git log -1 | grep '.*\\[ci skip\\].*'", returnStatus: true)
                    echo "${result}"
                    if (result == 0) {
                        currentBuild.result = 'ABORTED'
                        error("ci skip found in last commit. Aborting build.")
                    }
                }
            }
        }

        stage('Setup conda env') {
            steps {
                sh """#!/bin/bash
                . ~/.bashrc
                conda list --name ${env.CONDA_ENV} || conda env create -n ${env.CONDA_ENV} --file conda-env-dev.yml
                """
            }
        }

        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    withSonarQubeEnv('SonarQube') {
                        withCredentials([string(credentialsId: 'SonarQube', variable: 'TOKEN')]) {
                            sh '$SONAR_HOME/sonar-scanner -Dsonar.token=\"$TOKEN\" -Dsonar.qualitygate.wait=true -Dsonar.branch.name=$BRANCH_NAME'
                        }
                    }
                }
            }
        }

        stage('PyPI Package and Deploy') {
            when {
                branch 'master'
            }
            steps {
                sh """#!/bin/bash
                . ~/.bashrc
                set -e
                . ~/.bashrc
                conda activate hatch_cicd
                echo " *** Bump version"
                hatch version minor

                echo " *** Build package"
                hatch build --clean

                echo "*** Deploy package"
		hatch publish -r pypi-internal

                echo "*** Commit changes"
                git push git@gitlab.mercator-ocean.fr:mercator/qualif/TEP_CLASS4_creation.git HEAD:master
                git push --tags
                """
            }
        }
    }

    post{
        changed {
            emailext to: "cregnier@mercator-ocean.fr",
            subject: "Jenkins build:${currentBuild.currentResult}: ${env.JOB_NAME}",
            body: "${currentBuild.currentResult}: Job ${env.JOB_NAME}\nMore Info can be found here: ${env.BUILD_URL}",
            attachLog: true
        }
    }
}

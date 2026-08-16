// KijaniKiosk Payments — CI Pipeline
//
// Design principles applied this week, composed here:
//   - Fail fast: Lint runs before Build; nothing expensive runs on
//     code that doesn't even pass static checks.
//   - Parallel verification: Test and Security Audit run concurrently
//     since neither depends on the other's outcome, cutting wall-clock
//     time without weakening either check.
//   - Explicit environment: every value the pipeline depends on is
//     declared here, not inherited from whatever happens to be on the
//     agent's PATH or environment.
//   - Credentials never touch disk longer than necessary: the Nexus
//     .npmrc is written and deleted inside the same shell step that
//     uses it.
//
// Docker networking note (Challenge A): this pipeline runs on Docker
// Desktop, where Jenkins itself is a container with the host's Docker
// socket mounted — any container this pipeline spins up is a sibling
// container on the same engine as Nexus, not nested inside it. Docker
// Desktop provides every container a `host.docker.internal` DNS name
// that resolves to the host, which is what NEXUS_URL uses below. This
// is a cleaner equivalent to the brief's suggested bridge-IP approach
// (172.17.0.1), specific to Docker Desktop rather than native Linux
// Docker.

pipeline {
    agent {
        docker {
            image 'node:20.11.1-alpine3.19'
        }
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 10, unit: 'MINUTES')
    }

    environment {
        APP_NAME             = 'kijanikiosk-payments'
        NEXUS_URL            = 'http://host.docker.internal:8081'
        NEXUS_REPOSITORY     = 'npm-hosted'
        NEXUS_CREDENTIALS_ID = 'nexus-credentials'
        GIT_SHA_SHORT        = "${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'nogit'}"
    }

    stages {

        stage('Lint') {
            steps {
                sh 'npm install'
                sh 'npm run lint'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        sh 'npm test'
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'reports/junit.xml'
                        }
                    }
                }
                stage('Security Audit') {
                    steps {
                        // --audit-level=high: fails the branch on high/critical
                        // findings only, so routine low-severity advisories in
                        // transitive dev dependencies don't block every build.
                        sh 'npm audit --audit-level=high'
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                script {
                    def baseVersion = sh(
                        script: "node -p \"require('./package.json').version\"",
                        returnStdout: true
                    ).trim()
                    env.PACKAGE_VERSION = "${baseVersion}-${env.GIT_SHA_SHORT}"
                }
                sh '''
                    npm pack
                    mv ${APP_NAME}-*.tgz ${APP_NAME}-${PACKAGE_VERSION}.tgz
                '''
                archiveArtifacts artifacts: "${env.APP_NAME}-*.tgz", fingerprint: true
            }
        }

        stage('Publish') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: env.NEXUS_CREDENTIALS_ID,
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                        npm version ${PACKAGE_VERSION} --no-git-tag-version --allow-same-version

                        NEXUS_HOST_PATH="host.docker.internal:8081/repository/${NEXUS_REPOSITORY}/"
                        AUTH_TOKEN=$(printf "%s:%s" "$NEXUS_USER" "$NEXUS_PASS" | base64 | tr -d '\\n')

                        cat > .npmrc << EOF
//${NEXUS_HOST_PATH}:_auth=${AUTH_TOKEN}
registry=${NEXUS_URL}/repository/${NEXUS_REPOSITORY}/
always-auth=true
EOF

                        npm publish

                        rm -f .npmrc
                    '''
                }
            }
        }
    }

    post {
        always {
            // Workspace cleanup and test-result capture happen on every
            // run regardless of outcome, so a failed run never leaves
            // stale state for the next one.
            cleanWs()
        }
        success {
            echo "Published: ${env.NEXUS_URL}/repository/${env.NEXUS_REPOSITORY}/${env.APP_NAME}/-/${env.APP_NAME}-${env.PACKAGE_VERSION}.tgz"
        }
        failure {
            echo "Pipeline FAILED at build ${env.BUILD_NUMBER}. Notify #kijanikiosk-eng (placeholder for real chat-ops integration)."
        }
        changed {
            echo "Build status changed from previous run: now ${currentBuild.currentResult}."
        }
    }
}
// CI verified

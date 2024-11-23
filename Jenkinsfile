pipeline {
    agent any

    environment {
        RUST_SERVER_REGISTRY = 'your-docker-hub-username'
        RUST_SERVER_NAME = 'flick-server'
        FLUTTER_APP_NAME = 'flick-client'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Backend - Rust Build & Test') {
            steps {
                dir('rust_server') {
                    sh '''
                        rustc --version
                        cargo build
                        cargo test
                        cargo clippy -- -D warnings
                    '''
                }
            }
        }

        stage('Frontend - Flutter Build') {
            steps {
                dir('flutter_client') {
                    sh '''
                        flutter pub get
                        flutter test
                        flutter build web --release
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    // Rust 서버 이미지 빌드
                    dir('rust_server') {
                        def serverImage = docker.build(
                            "${RUST_SERVER_REGISTRY}/${RUST_SERVER_NAME}:${BUILD_NUMBER}"
                        )
                        serverImage.tag("latest")
                    }
                }
            }
        }

        stage('Deploy Development') {
            when { branch 'develop' }
            steps {
                // 개발 환경 배포
                sh '''
                    cd rust_server
                    docker-compose up -d
                '''
            }
        }

        stage('Deploy Production') {
            when { branch 'main' }
            steps {
                // 프로덕션 환경 배포
                sh '''
                    docker-compose -f docker-compose.prod.yml up -d
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Build and deployment successful!'
        }
        failure {
            echo 'Build or deployment failed!'
        }
    }
}
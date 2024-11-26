#!/bin/bash

start_dev() {
    echo "Starting development environment..."
    
    # Jenkins가 실행 중이 아니면 시작
    if ! docker ps | grep -q jenkins; then
        echo "Starting Jenkins..."
        docker-compose -f docker-compose.jenkins.yml up -d
    fi

    # rust_server 환경 시작
    cd rust_server
    docker-compose up -d
    cd ..

    echo "Development environment is ready!"
}

stop_dev() {
    echo "Stopping development environment..."
    
    # rust_server 환경 중지
    cd rust_server
    docker-compose stop
    cd ..

    # Jenkins 중지 (선택적)
    # docker-compose -f docker-compose.jenkins.yml stop

    echo "Development environment stopped!"
}

case "$1" in
    "start")
        start_dev
        ;;
    "stop")
        stop_dev
        ;;
    *)
        echo "Usage: ./dev.sh {start|stop}"
        exit 1
        ;;
esac

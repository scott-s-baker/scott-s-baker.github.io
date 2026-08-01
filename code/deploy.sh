#!/usr/bin/env bash
set -euo pipefail

ENV="${1:?Usage: deploy.sh [staging|prod]}"

case "$ENV" in
  staging)
    HOST=192.168.1.126
    PATH_ROOT=/opt/prism-staging
    BRANCH=develop
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.staging.yml"
    ;;
  prod)
    HOST=192.168.1.104
    PATH_ROOT=/opt/prism
    BRANCH=main
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
    ;;
  *)
    echo "Unknown environment: $ENV"; exit 1
    ;;
esac

echo "==> Deploying branch '$BRANCH' to $ENV ($HOST)"

ssh root@"$HOST" "cd $PATH_ROOT && git pull origin $BRANCH || (cd /opt && git clone -b $BRANCH https://github.ibm.com/hrvoje-stanilovic/prism.git $(basename $PATH_ROOT))"

ssh root@"$HOST" "python3 -c \"import ast; ast.parse(open('$PATH_ROOT/app/main.py').read()); print('OK')\""

ssh root@"$HOST" "cd $PATH_ROOT && docker compose $COMPOSE_FILES up -d"

echo "==> Waiting for health check"
sleep 8
curl -sf "http://$HOST:8000/health" && echo "==> $ENV healthy" || { echo "==> $ENV FAILED health check (may be transient — retry curl once before treating as real)"; exit 1; }

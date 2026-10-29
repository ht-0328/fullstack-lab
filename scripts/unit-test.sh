#!/usr/bin/env bash
# 各サービスの単体テスト・型チェックを Docker の test ステージで実行する（ホストに JDK / Node は不要）。
# BFF は publish 済みのクライアントに依存するため、先に scripts/publish-clients.sh を実行しておく。
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; [[ -f .env ]] && source .env; set +a

docker build --target test ./api
docker build --target test ./authz
docker build --target test ./auth
docker build --target test --network host \
  --build-arg "MAVEN_REPO_URL=${MAVEN_REPO_URL:-http://localhost:${REPOSILITE_HOST_PORT:-8081}/releases}" \
  -f web/bff/Dockerfile web
docker build --target typecheck -f web/frontend/Dockerfile web
echo "Unit tests and typecheck passed"

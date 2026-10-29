#!/usr/bin/env bash
# 起動中の Docker Compose 環境に対して、実ブラウザ（Playwright）で画面の E2E テストを実行する。
# ホストに Node.js やブラウザは不要（Playwright の公式イメージを使う）。テストは web/e2e にある。
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; [[ -f .env ]] && source .env; set +a

PORT="${NGINX_HOST_PORT:-8080}"
docker run --rm --network host --add-host admin.localhost:127.0.0.1 \
  -u "$(id -u):$(id -g)" -e HOME=/tmp -e CI="${CI:-}" \
  -e E2E_BASE_URL="http://localhost:$PORT" \
  -e E2E_STAFF_BASE_URL="http://admin.localhost:$PORT" \
  -e E2E_USER_PASSWORD="${LOCAL_TEST_USER_PASSWORD:-password}" \
  -v "$PWD/web/e2e:/e2e" -w /e2e \
  mcr.microsoft.com/playwright:v1.64.1-noble \
  sh -c 'npm ci --no-audit --no-fund --silent && npx playwright test "$@"' -- "$@"

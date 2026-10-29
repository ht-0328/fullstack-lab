#!/usr/bin/env bash
# 起動中の Docker Compose 環境の API・認可 API・認証 API に対して、Karate のテストを実行する。
# 各リポジトリは compose.test.yaml で単体でも同じテストを実行できる。ここでは全体構成の中で動かす。
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; [[ -f .env ]] && source .env; set +a
NETWORK="${COMPOSE_NETWORK:-fullstack-lab_default}"

docker build -q -t fullstack-lab-karate ./api/karate > /dev/null
for svc in api authz auth; do
  echo "== $svc"
  # 認証 API のテストは、登録したユーザーで IdP からトークンが取れるかも確かめるため Keycloak の接続先とクライアントのシークレットを渡す
  docker run --rm --network "$NETWORK" -e BASE_URL="http://$svc:8080" \
    -e KEYCLOAK_URL=http://keycloak:8080 -e AUTH_API_CLIENT_ID=auth-api -e AUTH_API_CLIENT_SECRET \
    -v "$PWD/$svc/karate:/karate:ro" fullstack-lab-karate
done

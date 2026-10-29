#!/usr/bin/env bash
# OpenAPI の仕様から、各リポジトリの生成コードを生成し直す（ホストに JDK / Node は不要）。
# 生成コードは git で管理する（docs/adr/ADR-0003-commit-generated-code.md）。仕様を変えたらこれを実行し、生成物も同じコミットに含める。
# Docker の test / typecheck ステージ（check-generated）が、仕様と生成物のずれを検出する。
set -euo pipefail
cd "$(dirname "$0")/.."

GRADLE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fullstack-lab/gradle"
NPM_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fullstack-lab/npm"
mkdir -p "$GRADLE_CACHE" "$NPM_CACHE"

# 引数: マウントするディレクトリ、その中の作業ディレクトリ
gradle_generate() {
  docker run --rm --network host -u "$(id -u):$(id -g)" \
    -e HOME=/cache -e GRADLE_USER_HOME=/cache \
    -v "$GRADLE_CACHE:/cache" -v "$PWD/$1:/w" -w "/w/$2" \
    eclipse-temurin:21-jdk-noble ./gradlew generate --no-daemon -q 2>&1 | { grep -v '^#' || true; }
  return "${PIPESTATUS[0]}"
}

for svc in api authz auth; do
  [[ -f "$svc/build.gradle.kts" ]] || continue  # 未取得のサブモジュールは飛ばす
  echo "[$svc] コントローラーのインターフェースと DTO（src/generated）、クライアント（client/src/generated）"
  gradle_generate "$svc" .
done

echo "[web/bff] BFF のインターフェースと DTO（bff/src/generated）"
gradle_generate web bff

echo "[web/frontend] 画面の型（frontend/app/types/bff.d.ts）"
docker run --rm -u "$(id -u):$(id -g)" \
  -e HOME=/cache -e npm_config_cache=/cache/npm \
  -v "$NPM_CACHE:/cache" -v "$PWD/web:/w" -w /w/frontend \
  node:24-alpine sh -c "npm ci --no-audit --no-fund --silent && npm run generate:bff --silent"

echo
echo "生成物の差分（あれば仕様の変更と同じコミットに含める）:"
for repo in api authz auth web; do
  [[ -e "$repo/.git" ]] || continue
  git -C "$repo" status --short | grep -E 'generated|bff\.d\.ts' | sed "s|^|[$repo] |" || true
done

#!/usr/bin/env bash
# API・認可 API・認証 API のクライアント（OpenAPI から生成した Kotlin ライブラリ）を、ローカルの Maven リポジトリ（Reposilite）へ publish する。
# BFF はソースではなくこの成果物にバージョンで依存する（AWS では CodeArtifact が同じ役割を担う）。
# 同じバージョンは上書きしない（CodeArtifact と同じ）。契約を変えたら gradle.properties と openapi の info.version を上げる。
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; [[ -f .env ]] && source .env; set +a

PUBLISH_URL="${MAVEN_REPO_PUBLISH_URL:-http://localhost:${REPOSILITE_HOST_PORT:-8081}/releases}"
GRADLE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fullstack-lab/gradle"
mkdir -p "$GRADLE_CACHE"

docker compose up -d --wait reposilite

for svc in api authz auth; do
  version=$(sed -nE 's/^version=(.+)$/\1/p' "$svc/gradle.properties")
  artifact="$svc-client"
  if curl -fsS -o /dev/null 2>/dev/null "$PUBLISH_URL/com/example/fullstacklab/$artifact/$version/$artifact-$version.pom"; then
    echo "[$svc] $artifact:$version は publish 済み（上書きしない。変更したらバージョンを上げる）"
    continue
  fi
  echo "[$svc] $artifact:$version を生成して publish する"
  docker run --rm --network host -u "$(id -u):$(id -g)" \
    -e HOME=/cache -e GRADLE_USER_HOME=/cache \
    -e MAVEN_REPO_PUBLISH_URL="$PUBLISH_URL" -e MAVEN_REPO_USER -e MAVEN_REPO_PASSWORD \
    -v "$GRADLE_CACHE:/cache" -v "$PWD/$svc:/w" -w /w \
    eclipse-temurin:21-jdk-noble ./gradlew :client:publish --no-daemon -q
done
echo "published: $PUBLISH_URL/com/example/fullstacklab/"

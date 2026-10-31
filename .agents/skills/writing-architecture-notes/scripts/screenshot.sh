#!/usr/bin/env bash
# 図解ページを Playwright の Docker イメージ（e2e と同じ）で撮る。ホストにブラウザは要らない。
# 使い方: screenshot.sh <architecture-notes のルート> <ページの相対パス> <出力ディレクトリ>
# 例:     screenshot.sh references/architecture-notes auth/authentication-authorization.html /tmp/shots
set -euo pipefail
root=$(cd "$1" && pwd); page=$2; out=$(mkdir -p "$3" && cd "$3" && pwd)
here=$(cd "$(dirname "$0")" && pwd)
image=mcr.microsoft.com/playwright:v1.64.1-noble
docker run --rm -v "$root:/work:ro" -v "$here/screenshot.js:/shot/screenshot.js:ro" -v "$out:/out" "$image" bash -c '
  set -e; mkdir -p /tmp/pw && cd /tmp/pw && npm init -y >/dev/null 2>&1
  npm i --no-audit --no-fund playwright@1.64.1 >/dev/null 2>&1
  cp /shot/screenshot.js . && node screenshot.js "file:///work/'"$page"'" /out
  chown -R '"$(id -u):$(id -g)"' /out'
echo "画像: $out（Read で開いて、はみ出し・重なり・色の意味を目で確かめる）"

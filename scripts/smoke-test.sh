#!/usr/bin/env bash
# 起動中の Docker Compose 環境に対し、Nginx を入口として主要な通信経路と認証・認可を確認する。
# 前提: docker compose up -d --wait 済み。必要なコマンドは curl・grep・sed・docker のみ。
# ログインは curl で実際の画面遷移（oauth2-proxy → Keycloak のログインフォーム → コールバック）をたどる。
set -euo pipefail
cd "$(dirname "$0")/.."

# .env の値（ポートやテストユーザーのパスワード）を使う
if [[ -f .env ]]; then set -a; source .env; set +a; fi

PORT="${NGINX_HOST_PORT:-8080}"
CUSTOMER_URL="http://localhost:$PORT"
STAFF_URL="http://admin.localhost:$PORT"
PASSWORD="${LOCAL_TEST_USER_PASSWORD:?LOCAL_TEST_USER_PASSWORD is required (.env)}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
failures=0

pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n       %s\n' "$1" "$2"; failures=$((failures + 1)); }

# check <説明> <期待する HTTP ステータス> <本文に含まれるべき文字列（空なら確認しない）> <curl 引数...>
check() {
  local name="$1" want_status="$2" want_body="$3"; shift 3
  local body status
  body=$(curl -sS -w '\n%{http_code}' "$@") || { fail "$name" "curl failed"; return; }
  status="${body##*$'\n'}"; body="${body%$'\n'*}"
  if [[ "$status" != "$want_status" ]]; then
    fail "$name" "status=$status (want $want_status) body=${body:0:200}"
  elif [[ -n "$want_body" && "$body" != *"$want_body"* ]]; then
    fail "$name" "body does not contain '$want_body': ${body:0:200}"
  else
    pass "$name"
  fi
  LAST_BODY="$body"
}

# login <サイトの URL> <ユーザー名> [パスワード]: ログインして Cookie ファイルのパスを COOKIES に入れる（毎回新しいセッションで入り直す）
login() {
  local base="$1" user="$2" password="${3:-$PASSWORD}" page action
  COOKIES="$WORK_DIR/$user.cookies"
  : > "$COOKIES"
  page=$(curl -sS -L -c "$COOKIES" -b "$COOKIES" "$base/")
  action=$(grep -o 'id="kc-form-login"[^>]*action="[^"]*"' <<<"$page" | sed -E 's/.*action="([^"]*)".*/\1/; s/&amp;/\&/g' || true)
  if [[ -z "$action" ]]; then fail "$user でログインする" "login form not found"; return; fi
  curl -sS -L -o /dev/null -c "$COOKIES" -b "$COOKIES" \
    --data-urlencode "username=$user" --data-urlencode "password=$password" "$action"
  check "$user でログインする" 200 "\"name\":\"$user\"" -b "$COOKIES" "$base/bff/me"
}

# create_task <説明> <期待ステータス> <Cookie> <サイト URL> <JSON>: 登録した ID を CREATED_ID に入れる
create_task() {
  check "$1" "$2" "" -b "$3" -X POST "$4/bff/tasks" -H 'Content-Type: application/json' -d "$5"
  CREATED_ID=$(sed -nE 's/.*"id":([0-9]+).*/\1/p' <<<"$LAST_BODY")
}

echo "Smoke test against $CUSTOMER_URL and $STAFF_URL"

echo "[入口と未認証アクセス]"
check "Nginx が応答する" 200 "ok" "$CUSTOMER_URL/nginx-health"
check "API は入口から公開されていない" 404 "" "$CUSTOMER_URL/api/tasks"
check "未認証で画面を開くとログインへリダイレクトされる" 302 "" "$CUSTOMER_URL/"
check "未認証の BFF 呼び出しは 401（リダイレクトしない）" 401 "login required" "$CUSTOMER_URL/bff/me"
check "未認証で偽のトークンヘッダーを付けても 401" 401 "" -H 'X-Amzn-Oidc-Accesstoken: forged' "$CUSTOMER_URL/bff/me"

echo "[ログイン（oauth2-proxy + Keycloak）]"
login "$CUSTOMER_URL" alice; ALICE=$COOKIES
login "$CUSTOMER_URL" bob;   BOB=$COOKIES
login "$STAFF_URL" carol;    CAROL=$COOKIES
login "$STAFF_URL" dave;     DAVE=$COOKIES
check "一般利用者として識別される" 200 '"userType":"CUSTOMER"' -b "$ALICE" "$CUSTOMER_URL/bff/me"
check "社員は Okta 互換の groups クレームからロールを得る" 200 '"roles":["task-viewer"]' -b "$CAROL" "$STAFF_URL/bff/me"
check "一般利用者のセッションは管理画面では使えない" 401 "" -b "$ALICE" "$STAFF_URL/bff/me"
check "ログイン後に送った偽のトークンヘッダーは上書きされる" 200 '"name":"alice"' \
  -b "$ALICE" -H 'X-Amzn-Oidc-Accesstoken: forged' "$CUSTOMER_URL/bff/me"
forged_status=$(docker compose exec -T nuxt sh -c \
  "wget -q -O /dev/null -S --header 'x-amzn-oidc-accesstoken: eyJhbGciOiJub25lIn0.eyJzdWIiOiJ4In0.' http://bff:8080/bff/me 2>&1 | head -1" || true)
if [[ "$forged_status" == *401* ]]; then pass "BFF は署名のない JWT を拒否する（コンテナ内から直接）"
else fail "BFF は署名のない JWT を拒否する（コンテナ内から直接）" "$forged_status"; fi

echo "[認可（BFF → 認可 API）]"
create_task "一般利用者はタスクを登録できる（期限日=祝日）" 201 "$ALICE" "$CUSTOMER_URL" \
  '{"title":"smoke: alice の祝日タスク","description":"smoke test","dueDate":"2026-11-03"}'
alice_task=$CREATED_ID
check "本人の一覧に表示される" 200 "\"id\":$alice_task" -b "$ALICE" "$CUSTOMER_URL/bff/tasks"
check "他の一般利用者の詳細は 404（存在を隠す）" 404 "" -b "$BOB" "$CUSTOMER_URL/bff/tasks/$alice_task"
if curl -sS -b "$BOB" "$CUSTOMER_URL/bff/tasks" | grep -q "\"id\":$alice_task,"; then
  fail "他の一般利用者の一覧には表示されない" "bob can see task $alice_task"
else pass "他の一般利用者の一覧には表示されない"; fi
check "task-viewer の社員は全件の一覧で見られる" 200 "\"id\":$alice_task" -b "$CAROL" "$STAFF_URL/bff/tasks"
check "task-viewer の社員は詳細も見られる" 200 '"createdByName":"alice"' -b "$CAROL" "$STAFF_URL/bff/tasks/$alice_task"
create_task "task-viewer の社員は登録できない（403）" 403 "$CAROL" "$STAFF_URL" '{"title":"smoke: carol"}'
create_task "task-admin の社員は登録できる" 201 "$DAVE" "$STAFF_URL" '{"title":"smoke: dave"}'
check "画面の出し分け用の権限が返る（task-viewer は登録不可）" 200 '"canCreateTask":false' -b "$CAROL" "$STAFF_URL/bff/me"

echo "[BFF → API → PostgreSQL / WireMock]"
check "詳細で外部サービスの補足情報を集約する" 200 '"holidayName":"文化の日"' -b "$ALICE" "$CUSTOMER_URL/bff/tasks/$alice_task"
check "入力エラーは 400 が画面側まで返る" 400 '"status":400' \
  -b "$ALICE" -X POST "$CUSTOMER_URL/bff/tasks" -H 'Content-Type: application/json' -d '{"title":""}'
create_task "期限日=障害スタブのタスクを登録できる" 201 "$ALICE" "$CUSTOMER_URL" '{"title":"smoke: 障害","dueDate":"2099-12-31"}'
check "外部 500 でも詳細は 200 で UNAVAILABLE になる" 200 '"dueDateInfoStatus":"UNAVAILABLE"' -b "$ALICE" "$CUSTOMER_URL/bff/tasks/$CREATED_ID"
create_task "期限日=遅延スタブのタスクを登録できる" 201 "$ALICE" "$CUSTOMER_URL" '{"title":"smoke: 遅延","dueDate":"2099-01-01"}'
check "外部の遅延はタイムアウトして UNAVAILABLE になる" 200 '"dueDateInfoStatus":"UNAVAILABLE"' -b "$ALICE" "$CUSTOMER_URL/bff/tasks/$CREATED_ID"

echo "[タスクの完了（設計書 0004）: BFF → 認可 API → API → DB]"
create_task "完了にするタスクを登録する" 201 "$ALICE" "$CUSTOMER_URL" '{"title":"smoke: 完了"}'
done_task=$CREATED_ID
check "詳細で本人には完了ボタンの出し分けが true で返る" 200 '"canComplete":true' -b "$ALICE" "$CUSTOMER_URL/bff/tasks/$done_task"
check "他の一般利用者は完了にできない（403）" 403 "許可されていません" -b "$BOB" -X POST "$CUSTOMER_URL/bff/tasks/$done_task/complete"
check "task-viewer の社員は完了にできない（403）" 403 "許可されていません" -b "$CAROL" -X POST "$STAFF_URL/bff/tasks/$done_task/complete"
check "本人は完了にできる（完了後はボタンを出さない）" 200 '"canComplete":false' -b "$ALICE" -X POST "$CUSTOMER_URL/bff/tasks/$done_task/complete"
completed_at=$(sed -nE 's/.*"completedAt":"([^"]+)".*/\1/p' <<<"$LAST_BODY")
check "もう一度完了にしても 200 で、完了日時は変わらない（冪等）" 200 "\"completedAt\":\"$completed_at\"" \
  -b "$ALICE" -X POST "$CUSTOMER_URL/bff/tasks/$done_task/complete"
check "一覧にも完了日時が載る（完了したタスクを隠さない）" 200 "\"completedAt\":\"$completed_at\"" -b "$ALICE" "$CUSTOMER_URL/bff/tasks"
create_task "task-admin が完了にするタスクを登録する" 201 "$ALICE" "$CUSTOMER_URL" '{"title":"smoke: 管理者が完了"}'
check "task-admin の社員は他人のタスクも完了にできる" 200 '"completedAt":"' -b "$DAVE" -X POST "$STAFF_URL/bff/tasks/$CREATED_ID/complete"
check "存在しないタスクの完了は 404" 404 "" -b "$ALICE" -X POST "$CUSTOMER_URL/bff/tasks/999999999/complete"

echo "[会員登録とパスワード変更: 公開パス → BFF → 認証 API → Keycloak]"
NEW_USER="smoke-$(date +%s)@example.com"
signup_json() { printf '{"email":"%s","familyName":"山田","givenName":"太郎","password":"%s"}' "$1" "$2"; }
check "未認証で会員登録画面を開ける（公開パス、SSR）" 200 "会員登録" "$CUSTOMER_URL/signup"
check "公開パスに偽のトークンヘッダーを付けても未認証として描画される" 200 "未認証" -H 'X-Amzn-Oidc-Accesstoken: forged' "$CUSTOMER_URL/signup"
check "管理画面のホストには公開パスが無い（ログインへリダイレクト）" 302 "" "$STAFF_URL/signup"
check "未認証で会員登録できる" 201 "\"email\":\"$NEW_USER\"" \
  -X POST "$CUSTOMER_URL/bff/signup" -H 'Content-Type: application/json' -d "$(signup_json "$NEW_USER" password-1)"
check "登録済みのメールアドレスは 409" 409 "登録済み" \
  -X POST "$CUSTOMER_URL/bff/signup" -H 'Content-Type: application/json' -d "$(signup_json "$NEW_USER" password-1)"
check "入力エラー（短いパスワード）は 400" 400 '"status":400' \
  -X POST "$CUSTOMER_URL/bff/signup" -H 'Content-Type: application/json' -d "$(signup_json "x-$NEW_USER" short)"
check "会員登録以外の BFF は未認証では呼べない" 401 "" \
  -X PUT "$CUSTOMER_URL/bff/me/password" -H 'Content-Type: application/json' -d '{"currentPassword":"a","newPassword":"password-2"}'
login "$CUSTOMER_URL" "$NEW_USER" password-1; NEW=$COOKIES
check "登録した利用者は一般利用者として識別され、パスワード変更が可能" 200 '"canChangePassword":true' -b "$NEW" "$CUSTOMER_URL/bff/me"
check "現在のパスワードが違えば 403（認証 API が Keycloak で確認）" 403 "現在のパスワードが違います" \
  -b "$NEW" -X PUT "$CUSTOMER_URL/bff/me/password" -H 'Content-Type: application/json' -d '{"currentPassword":"wrong-password","newPassword":"password-2"}'
check "パスワードを変更できる" 204 "" \
  -b "$NEW" -X PUT "$CUSTOMER_URL/bff/me/password" -H 'Content-Type: application/json' -d '{"currentPassword":"password-1","newPassword":"password-2"}'
login "$CUSTOMER_URL" "$NEW_USER" password-2
check "社員はパスワード変更できない（認可 API が拒否）" 403 "許可されていません" \
  -b "$DAVE" -X PUT "$STAFF_URL/bff/me/password" -H 'Content-Type: application/json' -d '{"currentPassword":"password","newPassword":"password-2"}'
check "社員にはパスワード変更の導線を出さない" 200 '"canChangePassword":false' -b "$CAROL" "$STAFF_URL/bff/me"

echo "[画面: ブラウザ → Nginx → Nuxt(SSR) → BFF]"
check "マイページの一覧が SSR で描画される" 200 "smoke: alice の祝日タスク" -b "$ALICE" "$CUSTOMER_URL/"
check "管理画面の一覧が SSR で描画される" 200 "すべてのタスク" -b "$CAROL" "$STAFF_URL/"
check "詳細画面が SSR で補足情報まで描画される" 200 "休日（文化の日）" -b "$ALICE" "$CUSTOMER_URL/tasks/$alice_task"
check "完了したタスクの詳細画面が SSR で完了日時まで描画される" 200 "完了（" -b "$ALICE" "$CUSTOMER_URL/tasks/$done_task"

echo "[OpenAPI 仕様（Swagger UI）]"
check "未認証では Swagger UI もログインへリダイレクトされる" 302 "" "$CUSTOMER_URL/swagger/"
check "ログイン後は Swagger UI が開ける" 200 "swagger-ui" -b "$ALICE" "$CUSTOMER_URL/swagger/"
for spec in bff api authz auth; do
  check "$spec の OpenAPI 仕様が配信される" 200 "openapi: 3.0" -b "$ALICE" "$CUSTOMER_URL/swagger/specs/$spec.yaml"
done

echo "[ログアウト]"
check "ログアウトするとトップへ戻る" 302 "" -b "$ALICE" -c "$ALICE" "$CUSTOMER_URL/oauth2/sign_out?rd=/"
check "ログアウト後の BFF 呼び出しは 401" 401 "" -b "$ALICE" "$CUSTOMER_URL/bff/me"
if curl -sS -L -b "$ALICE" -c "$ALICE" "$CUSTOMER_URL/" | grep -q 'kc-form-login'; then
  pass "IdP のセッションも終了し、再びログインフォームが出る"
else fail "IdP のセッションも終了し、再びログインフォームが出る" "auto-logged-in via IdP session"; fi

echo
if (( failures > 0 )); then
  echo "$failures check(s) failed"; exit 1
fi
echo "All checks passed"

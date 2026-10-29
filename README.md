# fullstack-lab

Nuxt、Kotlin + Spring Boot（BFF / 認証 API / 認可 API / API）、PostgreSQL、Nginx、Keycloak、oauth2-proxy、WireMock を組み合わせた、学習用のタスク管理アプリです。各技術の役割、リクエストの流れ、認証・認可、OpenAPI による契約と生成、複数リポジトリの連携を、Docker Compose 上で動かしながら確認できます。

```
                 ┌─ oauth2-proxy ─▶ Keycloak（ログイン画面 :8180）
                 │  （ALB の認証の代替）
ブラウザ ─▶ Nginx ─┼─▶ Nuxt（SSR）──┐
  (:8080)        │                 ▼            ┌─▶ 認可 API
                 ├─ /bff/* ──▶ BFF（JWT 検証）─┤
                 │                              └─▶ API ─┬─▶ PostgreSQL
                 └─ /swagger/ ─▶ Swagger UI              └─▶ WireMock（外部カレンダーAPI）

 Reposilite（Maven リポジトリ :8081）◀── api / authz がクライアントを publish、BFF が取得（CodeArtifact の代替）
```

- 構成、役割、リクエストの流れ、仮定 → [docs/architecture.md](docs/architecture.md)
- 設計書（機能ごと。実装の前に書く）→ [docs/design/](docs/design/README.md)、決定の記録 → [docs/adr/](docs/adr/)
- AWS と CI/CD の計画、費用の見込み → [docs/aws-roadmap.md](docs/aws-roadmap.md)
- AI エージェント向けのルールとスキル → [AGENTS.md](AGENTS.md)、[.agents/](.agents/README.md)

## リポジトリ構成

業務環境に合わせて、領域ごとにリポジトリを分けています。このリポジトリは集約用で、各領域を git submodule として参照します。領域同士はソースを共有せず、OpenAPI の契約と publish された成果物だけでつながります。

| リポジトリ | サブモジュールの場所 | 内容 |
|---|---|---|
| [fullstack-lab](https://github.com/ht-0328/fullstack-lab)（ここ） | — | Compose、Nginx、Keycloak（realm `staff`）、ドキュメント、スクリプト |
| [fullstack-lab-web](https://github.com/ht-0328/fullstack-lab-web) | `web/` | 画面（Nuxt）と BFF。契約は `web/openapi/bff.yaml` |
| [fullstack-lab-api](https://github.com/ht-0328/fullstack-lab-api) | `api/` | 業務 API、Flyway、WireMock のスタブ。契約は `api/openapi/api.yaml` |
| [fullstack-lab-authz](https://github.com/ht-0328/fullstack-lab-authz) | `authz/` | 認可 API。契約は `authz/openapi/authz.yaml` |
| [fullstack-lab-auth](https://github.com/ht-0328/fullstack-lab-auth) | `auth/` | 認証 API（Keycloak のユーザー管理の代行）と realm `customer` の定義。契約は `auth/openapi/auth.yaml` |

## 必要なもの

- Docker Engine 24 以上と Docker Compose v2.20 以上
- `git`、`curl`

JDK、Node.js、Gradle はホストに入れる必要はありません。ビルド、生成、テスト、publish はすべてコンテナの中で行います。

## 取得と起動

```bash
git clone --recurse-submodules https://github.com/ht-0328/fullstack-lab.git
cd fullstack-lab
cp .env.example .env               # 必要なら値を変更する（.env はコミットしない）
./scripts/publish-clients.sh        # 1. API / 認可 API のクライアントを生成して Reposilite へ publish
docker compose up -d --build --wait # 2. 全サービスを起動（ヘルスチェックが通るまで待つ）
```

起動が 2 段階なのは、BFF が API と認可 API の**ソースではなく publish された成果物**に依存するためです。業務環境で CodeArtifact が担う役割を、ローカルでは Reposilite が担います。`publish-clients.sh` は同じバージョンが publish 済みなら何もしません。

既に clone してある場合は `git submodule update --init --recursive` でサブモジュールを取得します。初回はイメージのビルドに数分かかります。

| URL | 内容 | ログイン |
|---|---|---|
| http://localhost:8080 | マイページ（一般利用者） | `alice`、`bob` |
| http://admin.localhost:8080 | 管理画面（社員。Okta の代わり） | `carol`（task-viewer：閲覧のみ）、`dave`（task-admin：登録も可） |
| http://localhost:8080/swagger/ | Swagger UI（3 つの OpenAPI 仕様。ログイン後） | 上のどれか |
| http://localhost:8180 | Keycloak の管理コンソール | `.env` の `KEYCLOAK_ADMIN_USER` / `KEYCLOAK_ADMIN_PASSWORD` |
| http://localhost:8081 | Reposilite（publish された成果物の一覧） | 閲覧は不要 |

テストユーザーのパスワードは `.env` の `LOCAL_TEST_USER_PASSWORD` です。`*.localhost` は Chrome・Firefox・Edge・curl では設定なしで 127.0.0.1 に解決されます。解決されない環境では、hosts ファイルに `127.0.0.1 admin.localhost` を追加してください。

## 動作確認

### 画面

1. http://localhost:8080 を開くと Keycloak のログイン画面へ移るので、`alice` でログインする
2. 一覧画面で「＋ タスクを登録」を押す
3. 期限日を入れて登録すると、詳細画面へ移る
4. 詳細画面の「期限日の補足（外部サービス）」の表示が、期限日によって変わることを確かめる
5. 別のブラウザ（またはシークレットウィンドウ）で認可の違いを確かめる
   - `bob` でログインすると、alice のタスクは一覧に出ず、詳細の URL を直接開いても「見つかりません」になる
   - http://admin.localhost:8080 に `carol` でログインすると、全員のタスクが見えるが登録ボタンは出ない
   - `dave` でログインすると、登録もできる
6. http://localhost:8080/swagger/ で BFF の仕様を開き、「Try it out」で `/bff/me` を呼ぶ（同一オリジンなのでログイン済みのまま呼べる）
7. 右上の「ログアウト」を押すと、Keycloak のセッションも終了し、再びログイン画面が出る
8. http://localhost:8080/signup は未認証で開ける公開ページ。会員登録すると、そのメールアドレスでログインできる。ログイン後は右上の「パスワード変更」で変えられる（社員には出ない）

| 期限日 | WireMock の応答 | 画面の表示 |
|---|---|---|
| 2026-11-03、2026-11-23 | 祝日 | 休日（文化の日 など） |
| 2099-12-31 | 500 エラー | 現在取得できません（縮退） |
| 2099-01-01 | 5 秒の遅延（API のタイムアウトは 3 秒） | 現在取得できません（縮退） |
| 上記以外 | 営業日 | 営業日 |
| 指定なし | 呼び出さない | 期限日なし |

### テスト

```bash
./scripts/smoke-test.sh   # 起動中の環境に Nginx 経由でリクエストし、主要な経路を確認する（curl）
./scripts/api-test.sh     # 起動中の API・認可 API・認証 API に対して Karate を実行する
./scripts/e2e-test.sh     # 起動中の環境に対して Playwright で画面を操作する（実ブラウザ）
./scripts/unit-test.sh    # 各サービスの単体テストと型チェック（Docker の test ステージで実行）
```

ホストに JDK・Node.js・ブラウザは要りません。Karate は JRE + 実行ファイルのイメージ、Playwright は公式イメージで動かします。

| テスト | 確認する経路 |
|---|---|
| [smoke-test.sh](scripts/smoke-test.sh) | 未認証時のリダイレクトと 401、curl による実際のログイン（4 ユーザー）、ホストをまたいだ Cookie の拒否、偽のトークンの拒否（Nginx と BFF の両方）、認可（所有者と社員ロール）、BFF → API → DB / WireMock、縮退、会員登録（公開パス、重複、入力エラー）とパスワード変更（不一致、成功、社員の拒否）、SSR、Swagger UI、ログアウト |
| `web/e2e`（Playwright） | 実ブラウザでの、ログイン・ログアウト、登録 → 詳細 → 一覧、縮退表示、他の利用者からの非表示、社員ロールによる表示と拒否、会員登録 → ログイン → パスワード変更 → 再ログイン。ブラウザ側の `openapi-fetch` と画面の出し分けはここでしか検証できない |
| `api/karate`（Karate） | 契約どおりの振る舞い（登録・取得・所有者での絞り込み・外部サービスの応答・入力エラー・404）。`api` 単体でも `compose.test.yaml` で実行できる |
| `authz/karate`（Karate） | 利用者の種別 × 操作 × 所有者の判定表、契約にない入力の 400 |
| `authz` の PolicyTest | 認可ルール（所有者、ロール、既定で拒否） |
| `auth/karate`（Karate） | 本物の Keycloak に対して、登録 → 参照 → 重複 409 → パスワード変更 → 新しいパスワードでトークンが取れること、入力エラー、404。`auth` 単体でも `compose.test.yaml` で実行できる |
| `auth` の CustomerAccountServiceTest | 認証 API → Keycloak（トークンの使い回し、ユーザー作成とロール付与の手順、409 / 404 / 不一致の変換、付与失敗時の削除） |
| `web/bff` の AccountServiceTest | BFF → 認可 API / 認証 API（社員の拒否時に認証 API を呼ばないこと、JWT の `sub` を利用者 ID に使うこと） |
| `web/bff` の CurrentUserFactoryTest | IdP ごとのクレームの違いの吸収（Keycloak の `realm_access.roles` と Okta 互換の `groups`） |
| `web/bff` の TaskViewServiceTest | 生成クライアント経由の BFF → 認可 API / API（一覧の絞り込み、拒否時に API を呼ばないこと、fail-closed、集約、縮退） |
| `api` の CalendarClientTest | API → 外部サービス（API キー、レスポンスの変換、エラーの扱い） |

### 中の様子を見る

```bash
docker compose ps                                   # 各サービスのヘルス状態
docker compose logs -f bff auth authz api           # [requestId=...] でサービスをまたいで追跡できる
docker compose logs authz | grep decision           # 認可の判定結果と理由
curl -si localhost:8080/bff/tasks | grep -i x-request-id
docker compose exec db psql -U fullstack_lab -d fullstack_lab -c 'select * from tasks'
docker compose exec db psql -U fullstack_lab -d fullstack_lab -c 'select version, description, success from flyway_schema_history'
docker compose exec wiremock curl -s localhost:8080/__admin/requests   # API から WireMock に届いたリクエスト
curl -s localhost:8081/api/maven/details/releases/com/example/fullstacklab | jq .   # publish 済みの成果物
```

（`psql` のユーザー名と DB 名は `.env` の値に合わせてください。）

## 停止

```bash
docker compose down        # 停止（DB と Reposilite のデータは残る）
docker compose down -v     # データ（ボリューム）も削除する。次回は publish からやり直す
```

## 構成

### ルーティング

| リクエスト | 経路 |
|---|---|
| 画面（`/`、`/tasks/*`、`/_nuxt/*`） | ブラウザ → Nginx → Nuxt |
| SSR 中のデータ取得 | Nuxt → `http://bff:8080/bff/*`（コンテナ間で直接。認証ヘッダーとリクエスト ID は Nuxt が転送する） |
| ブラウザからの API 呼び出し | ブラウザ → Nginx `/bff/*` → BFF（同一オリジンなので CORS は不要） |
| ログイン、ログアウト | ブラウザ → Nginx `/oauth2/*` → oauth2-proxy ⇄ Keycloak |
| OpenAPI 仕様の閲覧 | ブラウザ → Nginx `/swagger/` → Swagger UI（ログイン後） |
| 認可 | BFF → `http://authz:8080/authz/v1/decisions` |
| 会員登録（`/signup`、`/bff/signup`、`/_nuxt/*`） | ブラウザ → Nginx（認証なしの公開パス。一般利用者のホストのみ）→ Nuxt / BFF |
| アカウント操作 | BFF → `http://auth:8080/auth/v1/*` → Keycloak の Admin API |
| 業務 API | BFF → `http://api:8080/api/*`（入口からは 404） |
| 外部サービス | API → `http://wiremock:8080/v1/days/{date}`（`X-Api-Key` を付ける） |

### 認証と認可

| 利用者 | ホスト | IdP（ローカル） | IdP（AWS 想定） | 認可 |
|---|---|---|---|---|
| 一般利用者 | `localhost` | Keycloak の realm `customer` | Keycloak | 自分のタスクだけ |
| 社員 | `admin.localhost` | Keycloak の realm `staff`（Okta の代わり） | Okta | ロール（`groups` クレーム）による |

1. Nginx が `auth_request` で oauth2-proxy にセッションを確認させます（AWS では ALB の認証アクションが担当）。
2. 認証済みなら、IdP のアクセストークン（JWT）を、ALB と同じヘッダー名 `x-amzn-oidc-accesstoken` で後段へ渡します。
3. BFF が JWT の署名・`iss`・`aud`・有効期限を検証し、操作の前に認可 API へ問い合わせます。
4. 一般利用者のアカウントは認証 API（`auth/`）が Keycloak に作ります。会員登録の画面と API だけは認証なしで通します（[public-locations.conf](nginx/snippets/public-locations.conf)）。

詳しくは [docs/architecture.md](docs/architecture.md#認証と認可)、AWS との違いは [docs/aws-roadmap.md](docs/aws-roadmap.md#alb-の認証) にあります。

### 契約（OpenAPI）と生成物

各領域の境界は OpenAPI の仕様で定義し、仕様から両側のコードを生成します。生成コードは業務環境と同じく git で管理します（[ADR-0003](docs/adr/ADR-0003-commit-generated-code.md)）。仕様を変えたら `./scripts/generate.sh` で生成し直し、生成物も同じコミットに含めます。生成し忘れや手で直した生成コードは、各リポジトリの Docker の test ステージ（CI でも実行）が生成し直して差分を取り、落とします。

| 契約 | 提供側が生成するもの | 利用側が使うもの |
|---|---|---|
| `api/openapi/api.yaml` | コントローラーのインターフェースと DTO | クライアント `api-client`（Maven 成果物） |
| `authz/openapi/authz.yaml` | 同上 | クライアント `authz-client`（Maven 成果物） |
| `auth/openapi/auth.yaml` | 同上 | クライアント `auth-client`（Maven 成果物） |
| `web/openapi/bff.yaml` | BFF のコントローラーのインターフェースと DTO | 画面の型（`openapi-typescript`）＋ `openapi-fetch` の型付きクライアント |

**契約を変えるときの流れ（API の例）**

1. `api` で `openapi/api.yaml` と `gradle.properties` の `version` を上げ、`./scripts/generate.sh` で生成し直し、実装を合わせて PR を出す（生成物も同じ PR に含める）
2. CI が通り main に取り込まれると、CI が新しいバージョンのクライアントを publish する（ローカルでは `./scripts/publish-clients.sh`）
3. `web` で `bff/gradle.properties` の `apiClientVersion` を上げ、BFF の実装を合わせて PR を出す

古いバージョンは残るので、API と BFF を同時にデプロイする必要はありません。

### ディレクトリ

```
fullstack-lab/
├── compose.yaml                 # ローカル環境の定義
├── .env.example                 # 環境変数の雛形（.env は .gitignore 済み）
├── nginx/                       # 入口のプロキシ（ALB の代替）。conf.d がホスト別の server、snippets が共通部分
├── keycloak/import/             # realm staff の定義（Okta の代替）。realm customer は auth/keycloak/import にある
├── scripts/                     # 生成、publish、スモークテスト、Karate、Playwright、単体テスト
├── docs/                        # 構成の説明、設計書（design/）、ADR（adr/）、AWS の計画
├── references/architecture-notes/  (submodule)  # 仕組みの図解（人が読む HTML。設計書の正は docs/）
├── AGENTS.md / CLAUDE.md        # AI エージェント向けのルール（CLAUDE.md は AGENTS.md を取り込むだけ）
├── .agents/skills/              # スキル（設計書、契約変更、実装、PR）。.claude/skills はここへのリンク
├── .claude/agents/              # エージェント定義（design-review）
├── .github/                     # PR テンプレートと CI（Compose でのスモークテスト、Karate、Playwright）
├── web/      (submodule)        # 画面 + BFF
│   ├── openapi/bff.yaml
│   ├── frontend/                # Nuxt 4。app/ が画面、server/ が Nitro（healthz のみ）
│   ├── bff/                     # Spring Boot。JWT の検証、認可 API の呼び出し、画面向けの集約、縮退
│   └── e2e/                     # Playwright
├── api/      (submodule)        # Spring Boot。業務データ、Flyway、外部 API クライアント
│   ├── openapi/api.yaml
│   ├── client/                  # publish するクライアントライブラリ
│   ├── wiremock/                # 外部カレンダー API のスタブ
│   ├── karate/                  # Karate（契約どおりの振る舞い）
│   └── compose.test.yaml        # API と依存先だけを立てて Karate を実行する
├── authz/    (submodule)        # Spring Boot。認可 API（ポリシーは application.yml と Policy.kt）
│   ├── openapi/authz.yaml
│   ├── client/
│   ├── karate/
│   └── compose.test.yaml
└── auth/     (submodule)        # Spring Boot。認証 API（Keycloak の Admin API の前段）と realm customer の定義
    ├── openapi/auth.yaml
    ├── keycloak/import/
    ├── client/
    ├── karate/
    └── compose.test.yaml        # 認証 API と Keycloak だけを立てて Karate を実行する
```

### 環境変数

| 変数 | 使う場所 | 説明 |
|---|---|---|
| `NGINX_HOST_PORT` | nginx | ホストに公開するポート |
| `KEYCLOAK_HOST_PORT` | keycloak | ログイン画面と管理コンソールのポート |
| `KEYCLOAK_ADMIN_USER` / `KEYCLOAK_ADMIN_PASSWORD` | keycloak | 管理コンソールの管理者 |
| `LOCAL_TEST_USER_PASSWORD` | keycloak | テストユーザー共通のパスワード（realm の取り込み時に埋め込む） |
| `CUSTOMER_CLIENT_SECRET` / `STAFF_CLIENT_SECRET` | keycloak, oauth2-proxy | OIDC クライアントのシークレット |
| `AUTH_API_CLIENT_SECRET` | keycloak, auth | 認証 API が Admin API を呼ぶクライアント（サービスアカウント）のシークレット |
| `OAUTH2_PROXY_COOKIE_SECRET` | oauth2-proxy | セッション Cookie の暗号化キー |
| `REPOSILITE_HOST_PORT` | reposilite | Maven リポジトリのポート |
| `MAVEN_REPO_USER` / `MAVEN_REPO_PASSWORD` | reposilite, publish | publish 用のトークン（取得は匿名で可能） |
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | db, api | DB の接続情報 |
| `EXTERNAL_CALENDAR_API_KEY` | api | 外部 API のキー（ローカルではダミー） |

サービス間の URL は環境によって変わる値ですが秘密情報ではないので、`compose.yaml` に直接書いています。秘密情報には既定値を持たせていません（設定し忘れたら起動時に失敗します）。

## 開発の流れ

- 機能の追加・変更は、[docs/design/](docs/design/README.md) に設計書を書いてから実装します。設計書は既存の設計書（直近は 0005）と同じ節構成で書きます。AI に任せるときは、スキル `writing-design-doc` → `implementing-from-design` → `pr-and-commit` の順に使い、最後にエージェント `design-review` で設計書と実装のずれを確かめます（[AGENTS.md](AGENTS.md)）。[0005 認証 API と会員登録](docs/design/0005-auth-api-and-signup.md) はこの流れで実装した例、[0004 タスクの完了](docs/design/0004-task-completion.md) は未実装の設計書で、この流れを試す題材です
- 変更は各リポジトリでブランチを切り、PR を出して CI が通ってから main に取り込みます（main は直接 push できない設定です）。PR の本文は [.github/pull_request_template.md](.github/pull_request_template.md) に沿って書きます
- サブモジュールを更新したら、このリポジトリでも参照先のコミットを進める PR を出します
- CI の役割
  - `api` / `authz` / `auth`：PR で単体テストと Karate（`compose.test.yaml` で単体起動）。main に入ったらクライアントを GitHub Packages へ publish
  - `web`：PR で画面の型チェックと BFF の単体テスト（クライアントは GitHub Packages から取得）。Playwright は全体構成が要るため `fullstack-lab` で実行
  - `fullstack-lab`：PR でサブモジュールを含めて Compose を起動し、スモークテスト → Karate → Playwright

## バージョンと選定理由

| 技術 | バージョン | 理由 |
|---|---|---|
| Spring Boot | 4.1.1 | 3.5 系は OSS サポートが 2026-06 に終了している。4.1 系で 2 週間以上経った最新のパッチ版 |
| Kotlin | 2.3.21 | Spring Boot 4.1 が管理するバージョン |
| Java | 21（Temurin） | LTS。Spring Boot 4 と Kotlin 2.3 の両方が対応している |
| Gradle | 9.8.1 | Spring Boot 4 が対応する 9 系で、2 週間以上経った最新のパッチ版 |
| openapi-generator | 7.26.0 | `useSpringBoot4` / `useJackson3` に対応した版。Spring Boot 4 での生成とコンパイルを事前に確認した |
| Nuxt | 4.6.1 | 4 系で 2 週間以上経った最新のパッチ版 |
| Node.js | 24（Alpine） | Active LTS。Nuxt 4.6 の要件（^24.15）を満たす |
| TypeScript / vue-tsc | 5.9.3 / 3.3.13 | `openapi-typescript` 7.13 が TypeScript 5 系を要求するため、6 系ではなく 5 系の最終版にした |
| openapi-typescript / openapi-fetch | 7.13.0 / 0.17.0 | 型だけを生成し、HTTP の層は fetch に任せる組み合わせ（docs/architecture.md 参照） |
| PostgreSQL | 17（Alpine） | 安定して長く使われている系列。RDS でも利用できる |
| Nginx | 1.30（Alpine） | stable 系列 |
| WireMock | 3.13.2 | 3 系の最新安定版 |
| Keycloak | 26.7.5 | 26.7 系の最終パッチ版。26.8 系の最新パッチは公開から 2 週間未満のため見送った |
| oauth2-proxy | v7.15.5（Alpine） | 最新安定版。Alpine 版にしたのは、ヘルスチェックで wget を使うため |
| Reposilite | 3.6.3 | 軽量な Maven リポジトリ。3.6.4 以降は公開から 2 週間未満のため見送った |
| Swagger UI | v5.33.2 | 2 週間以上経った最新のパッチ版 |

Docker のベースイメージはマイナーバージョンまで固定し（`nginx:1.30-alpine` など）、セキュリティパッチは取り込めるようにしています。アプリの依存はパッチバージョンまで固定しています（`build.gradle.kts`、`package-lock.json`）。

## トラブルシューティング

- **`--wait` が失敗する**：`docker compose ps` で unhealthy のサービスを特定し、`docker compose logs <service>` で原因を確認します。API はマイグレーションに失敗すると再起動を繰り返します
- **BFF のビルドで `api-client` が見つからない**：`./scripts/publish-clients.sh` を先に実行します。`docker compose down -v` の後も同様です
- **`.env` を変えたのに反映されない**：`docker compose up -d` で、変更したサービスが作り直されます
- **スキーマを最初からやり直したい**：`docker compose down -v` で DB のボリュームを消します
- **ログイン後に 401 やログインのループが起きる**：古い Cookie が残っている可能性があります。`localhost` のサイトデータを削除してください。realm の設定を変えたときは `docker compose up -d --force-recreate keycloak` を実行します（Keycloak は開発モードで、ユーザーなどのデータはコンテナを作り直すと初期化されます）
- **`admin.localhost` が開けない**：hosts ファイルに `127.0.0.1 admin.localhost` を追加します
- **サブモジュールが空**：`git submodule update --init --recursive` を実行します（`references/architecture-notes` も含まれます）

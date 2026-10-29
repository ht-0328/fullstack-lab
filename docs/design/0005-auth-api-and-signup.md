# 0005 認証 API と会員登録の設計書

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-10-28 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-10-28 |
| 想定読者（宛先） | 認証 API を実装する開発者（人と AI）、構成をレビューする人 |
| この文書を読んだあと読者ができること | 認証 API の責務と境界、会員登録・パスワード変更の経路、影響するリポジトリと順序を説明できる |
| 実装 PR | fullstack-lab-auth#1、fullstack-lab-authz#3、fullstack-lab-web#4、fullstack-lab#6（設計書は fullstack-lab#4） |

## 解決する課題

業務環境にあった「認証 API」（独立したリポジトリで、Keycloak をその中に持つ）を再現し、一般利用者が自分でアカウントを作り、パスワードを変えられるようにする。

| 項目 | 内容 |
|---|---|
| 対象 | 一般利用者（マイページ）のアカウント管理。社員（Okta）は対象外 |
| 発生規模 | リポジトリ 1 つの追加（集約 1 + 領域 4）。契約 1 つの追加と 1 つの互換変更 |
| 読者への影響 | 今はテストユーザー（alice / bob）しかおらず、利用者を増やすには Keycloak の管理コンソールを使うしかない |
| 成功条件 | 未認証で会員登録画面を開いて登録し、そのままログインしてタスクを登録できる。ログイン後にパスワードを変え、新しいパスワードでログインし直せる。既存の認証（0002）の経路は変わらない |

## 制約と前提

| 区分 | 内容 | 根拠 |
|---|---|---|
| 制約 | 認証 API は独立したリポジトリで、Keycloak（の設定）をその中に持つ | 業務環境の事実（2026-10-28 の聞き取り） |
| 制約 | 社員のアカウントは扱わない | Okta は外部の SaaS で、アカウント管理はアプリの外にある |
| 制約 | 領域同士は契約（OpenAPI）と publish された成果物だけでつなぐ | [0003](0003-contracts-and-repositories.md) |
| 前提 | ログインは引き続き前段（ローカル: oauth2-proxy、AWS: ALB）が Keycloak のログイン画面へ誘導する | [0002](0002-authentication-authorization.md)。認証 API はログインに関与しない |
| 前提 | BFF が受け取る JWT の `sub` は Keycloak のユーザー ID である | Keycloak の仕様 |
| 仮定 | 認証 API の責務は「Keycloak のユーザー管理の代行」（登録、プロフィール参照、パスワード変更）とする | 業務の認証 API の責務は利用者も覚えていない（2026-10-28）。[architecture.md の仮定 12](../architecture.md#仮定) |
| 仮定 | 会員登録の画面と API は未認証で到達できる公開パスとし、入口（ALB / Nginx）が認証なしで転送する | ALB ではリスナールール単位で認証アクションを付けないことができる |
| 仮定 | メールアドレスの確認（確認メール）は行わない | ローカルにメール送信の仕組みが無い。登録時に `emailVerified = true` で作る |

## 影響するリポジトリ

| リポジトリ | 変更 | 変えない理由 |
|---|---|---|
| `auth`（新規 `fullstack-lab-auth`） | 認証 API 本体、契約 `openapi/auth.yaml`、クライアント `auth-client`、Keycloak の realm `customer` の定義、Karate | — |
| `authz` | `application.yml` の `customer-actions` に `account:change-password` を追加。Karate に判定を追加 | 契約（`openapi/authz.yaml`）は変えない。判定ロジック（`Policy`）も変えない |
| `web` | BFF: `auth-client` への依存、`/bff/signup`（公開）と `/bff/me/password`、`Capabilities.canChangePassword`。画面: `/signup` と `/me/password`。Playwright | — |
| 集約 | サブモジュール `auth/` の追加、Compose（`auth` サービス、Keycloak の realm の取り込み元）、Nginx の公開パス、スモークテスト、Swagger UI、スクリプト、ドキュメント | — |
| `api` | なし | 業務データ（タスク）は変わらない。利用者の識別は引き続き JWT の `sub` |

## 採用案

認証 API を Keycloak の Admin REST API の前段として置き、BFF はアカウントの操作を認証 API 経由でだけ行う。

| 要素 | 採用内容 | 責務 |
|---|---|---|
| リポジトリ `auth` | Kotlin + Spring Boot。`api` / `authz` と同じ構成（契約から生成、クライアントを publish、Karate を `compose.test.yaml` で実行） | 認証 API と、Keycloak の realm `customer` の定義（`auth/keycloak/import/customer-realm.json`） |
| 認証 API | `POST /auth/v1/customers`（登録）、`GET /auth/v1/customers/{id}`（参照）、`PUT /auth/v1/customers/{id}/password`（変更） | Keycloak の Admin API を呼び、入力の検証とエラーの変換（409 / 403 / 404）を行う。内部ネットワーク専用で、BFF を信頼する（API と同じ。[仮定 7](../architecture.md#仮定)） |
| Keycloak のクライアント `auth-api` | 機密クライアント。サービスアカウント（`realm-management` の `manage-users` と `view-users`）と、現在のパスワードの確認に使う Direct Access Grants を有効にする | 認証 API だけが使う。シークレットは `AUTH_API_CLIENT_SECRET` |
| realm `staff` | 集約リポジトリに残す（`keycloak/import/staff-realm.json`） | Okta の代替であり、業務環境には存在しない学習用の設定。認証 API は関与しない |
| BFF | `POST /bff/signup`（未認証で呼べる）、`PUT /bff/me/password`（認証済み。`sub` を利用者 ID にして認証 API を呼ぶ）、`GET /bff/me` の `capabilities.canChangePassword` | 認証 API のクライアント（`auth-client`）を使う。パスワード変更の前に認可 API へ `account:change-password` を問い合わせる |
| 認可 API | `customer-actions` に `account:change-password` を追加 | 一般利用者は自分のアカウントにだけ許可。社員はどのロールにも付与しないので拒否（Okta 側で管理するため） |
| 画面 | `/signup`（公開。登録後にログインへの導線）、`/me/password`（一般利用者のみ表示） | ブラウザから同一オリジンの `/bff/*` を呼ぶ。SSR では BFF の 401 を「未認証」として扱い、公開ページを描画する |
| 入口（Nginx） | 一般利用者のホストだけ、`/signup`、`/bff/signup`、`/_nuxt/` を `auth_request` なしで転送する。転送時に `X-Amzn-Oidc-*` ヘッダーを空にする | AWS では ALB のリスナールール（パス条件、認証アクションなし）に相当する。社員のホストには公開パスを作らない |

### 契約の変更

**`auth/openapi/auth.yaml`（新規、1.0.0）**。抜粋:

```yaml
paths:
  /auth/v1/customers:
    post:   # 201 CustomerAccount / 400 / 409（メールアドレス重複）
  /auth/v1/customers/{id}:
    get:    # 200 CustomerAccount / 404
  /auth/v1/customers/{id}/password:
    put:    # 204 / 400 / 403（現在のパスワード不一致）/ 404
components:
  schemas:
    RegisterCustomerRequest: { email, familyName, givenName, password(8 文字以上) }
    ChangePasswordRequest:   { currentPassword, newPassword(8 文字以上) }
    CustomerAccount:         { id, email, familyName, givenName }
```

**`web/openapi/bff.yaml`（1.0.0 → 1.1.0、互換）**。追加のみ:

```yaml
paths:
  /bff/signup:         post: SignupInput → 201 SignupResult / 400 / 409
  /bff/me/password:    put:  ChangePasswordInput → 204 / 400 / 401 / 403
components:
  schemas:
    Capabilities: { canCreateTask, canChangePassword }   # canChangePassword を追加
```

`authz/openapi/authz.yaml` は変えない（操作名は自由文字列）。

### 認可

| 操作 | 一般利用者 | 社員 | 備考 |
|---|---|---|---|
| 会員登録 | 未認証で可 | — | 主体が無いので認可 API に問い合わせない。乱用対策は未決ではなく課題として申し送る（下記） |
| `account:change-password` | 自分のアカウントのみ許可 | 拒否 | `authz/src/main/resources/application.yml` の `customer-actions` に追加。`staff-role-permissions` には追加しない |

### リクエストの流れ（会員登録）

1. ブラウザ → Nginx `/signup`（認証なし）→ Nuxt（SSR）。`app.vue` の `/bff/me` は 401 になるので「未認証」として描画する
2. ブラウザ → Nginx `/bff/signup`（認証なし）→ BFF → 認証 API `POST /auth/v1/customers` → Keycloak Admin API（ユーザー作成、パスワード設定、ロール `customer` の付与）
3. 画面が「ログインする」への導線（`/oauth2/start?rd=/`）を出し、以降は 0002 の流れでログインする

### テスト

| 層 | 対象 | 確かめること |
|---|---|---|
| 単体（`auth`） | Keycloak Admin API の呼び出し（MockRestServiceServer） | トークン取得、ユーザー作成とロール付与の順序、409 / 404 / 401 の変換、パスワードをログに出さない |
| 単体（`web/bff`） | 認証 API と認可 API の呼び出し | 社員の変更要求は認可 API で拒否して認証 API を呼ばない。`sub` を利用者 ID に使う |
| Karate（`auth`） | 実際の Keycloak を `compose.test.yaml` で立てる | 登録 → 参照 → 重複 409 → パスワード変更（不一致 403、成功 204）→ 新しいパスワードでトークンが取れる。入力エラー 400、未知の ID 404 |
| Karate（`authz`） | 判定表 | 一般利用者の `account:change-password`（本人 / 他人）、社員の拒否 |
| Playwright（`web/e2e`） | 画面 | 登録 → ログイン → タスク登録 → パスワード変更 → ログアウト → 新しいパスワードでログイン。社員にはパスワード変更の導線が出ない |
| スモーク（集約） | 入口 | 未認証で `/signup` と `/bff/signup` に到達できる。社員のホストでは 302。公開パスに付けた偽の `X-Amzn-Oidc-*` は捨てられる。`/bff/me/password` は未認証で 401 |

## 比較した代替案とトレードオフ

| 案 | 利点 | 欠点 | 採否の理由 |
|---|---|---|---|
| 認証 API を独立リポジトリに置き、Keycloak の Admin API の前段にする（採用） | 業務環境の境界と同じ。アカウント操作の入口が 1 つになり、Keycloak の都合（API の形、エラー）を BFF から隠せる | リポジトリと配布物が増える | 業務環境の事実に合わせる |
| Keycloak の登録画面（`registrationAllowed`）とアカウントコンソールを使う | 実装がほぼ不要 | 認証 API の再現にならない。画面の見た目と導線が Keycloak 任せになる | 不採用。再現が目的 |
| BFF が Keycloak の Admin API を直接呼ぶ | リポジトリが増えない | 認証 API が独立していたという事実に反する。BFF が Keycloak の管理権限を持つ | 不採用 |
| 認証 API がログイン（ID とパスワードからトークン発行）も担う | 画面でログインを完結できる | 前段（ALB）の認証と二重になり、0002 の経路を作り直すことになる | 不採用。業務の責務が不明なので、既存の経路を壊さない範囲に絞る |

## 失敗時の動作

| 失敗条件 | 検知方法 | システムの動作 | 利用者への影響 |
|---|---|---|---|
| Keycloak に到達できない | 認証 API の Admin API 呼び出しが失敗する | 認証 API は 503。BFF は 502 にまとめる | 登録・変更ができない。ログイン済みの利用者のタスク操作には影響しない |
| メールアドレスが登録済み | Keycloak が 409 を返す | 認証 API は 409（Problem Details）。BFF はそのまま返す | 画面に「登録済み」と表示する |
| 現在のパスワードが違う | Keycloak のトークン発行が `invalid_grant` | 認証 API は 403。BFF はそのまま返す | 画面に表示する。回数制限は Keycloak の既定（無効）のまま |
| 認証 API が停止している | BFF の呼び出しが失敗する | BFF は 502 | 登録・変更ができない |
| ユーザー作成後のロール付与に失敗する | Admin API のエラー | 認証 API は作成したユーザーを削除してから 503 を返す（登録は成功か失敗のどちらかにする） | 登録をやり直せる |
| 公開パスに偽の認証ヘッダーを付ける | — | Nginx が `X-Amzn-Oidc-*` を空に上書きする。BFF は `/bff/signup` 以外を認証必須にしている | なし |

## 技術観点の確認

該当しない観点は行ごと削り、該当しない理由を 1 行書いている（テンプレートの O-07）。

### セキュリティと権限

| 観点 | 内容 |
|---|---|
| 認証 | 認証 API は内部ネットワーク専用で、BFF を信頼する（API と同じ扱い）。Keycloak へはクライアント `auth-api` のサービスアカウント（`manage-users`、`view-users`、ロール ID の取得に `view-realm`）で接続する |
| 認可 | 認証 API 自身は認可しない。BFF が利用者 ID に `sub` を使い、他人のアカウントを指定できないようにする。パスワード変更は認可 API に問い合わせる |
| 秘密情報の保管 | `AUTH_API_CLIENT_SECRET` は `.env`（ローカル）/ Secrets Manager（AWS）。パスワードはログと例外メッセージに出さない |
| 通信の暗号化 | ローカルは HTTP。AWS では VPC 内の通信（API / 認可 API と同じ） |
| 監査ログ | 登録と変更を利用者 ID とリクエスト ID で記録する（メールアドレスとパスワードは出さない） |

### データ

| 観点 | 内容 |
|---|---|
| 扱う個人情報 | メールアドレス、氏名、パスワード。保持するのは Keycloak だけで、アプリの DB には持たない |
| 保持期間と削除 | 退会（削除）は本設計の範囲外。課題として申し送る |
| 移行 | 既存のテストユーザー（alice / bob）は realm の定義に残す。認証 API で作ったユーザーも同じ realm に入る |
| 容量の見込み | 学習用のため該当しない |

### 性能と可用性

学習用の構成で目標値を置かないため該当しない。Keycloak の起動を待たずに認証 API を起動し、トークンは最初の呼び出し時に取得する（BFF の公開鍵と同じ方針）。

### 可観測性

| 観点 | 内容 |
|---|---|
| ログ | `X-Request-Id` を認証 API まで引き継ぐ（`RequestIdFilter`）。Keycloak のエラー応答はステータスだけを記録する |
| メトリクス、アラート | 学習用のため該当しない |

### 展開と後始末

| 観点 | 内容 |
|---|---|
| 展開手順 | `auth`（新規、publish）→ `authz`（設定）→ `web`（契約 1.1.0、`authClientVersion`）→ 集約（サブモジュール、Compose、Nginx）。[`pr-and-commit`](../../.agents/skills/pr-and-commit/SKILL.md) の順序 |
| 切り戻し | 集約リポジトリの参照を前のコミットに戻す。`auth-client` 1.0.0 は残す |
| 互換性 | `bff.yaml` は追加のみ（互換）。`authz.yaml` は変えない。realm `customer` の定義は置き場所が変わるだけで内容は互換（クライアント `auth-api` の追加のみ） |
| 廃止計画 | なし |

## 未決事項

なし。2026-10-28 に次の 2 点を利用者に確認し、本文に反映した。

- 業務の認証 API の責務は不明（「わからない」）→ 「Keycloak のユーザー管理の代行」を仮定とした
- 画面までつなぐ → 会員登録画面とパスワード変更画面を含める

## 課題・申し送り事項

- 会員登録の乱用対策（レート制限、CAPTCHA、メールアドレスの確認）は含めない
- 退会（アカウント削除）と、プロフィールの変更は含めない
- Keycloak の総当たり対策（Brute Force Detection）は既定の無効のまま

# 0005 認証 API と会員登録の設計書

> **状態: 実装済み。** 2026-10-28 に未決事項 2 点を解消して承認し、2026-10-30 に実装した。

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-10-28 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-11-02 |
| 実装 PR | fullstack-lab-auth#1、fullstack-lab-authz#3、fullstack-lab-web#4、fullstack-lab#6（設計書は fullstack-lab#4） |
| 想定読者（宛先） | 認証 API を実装する開発者（人と AI）、構成をレビューする人 |
| この文書を読んだあと読者ができること | 認証 API の責務と境界、会員登録・パスワード変更の経路、影響するリポジトリと順序を説明できる |

## 解決する課題

業務環境（作成者が以前いた職場。このリポジトリはその構成を学習用に再現している。[用語](../architecture/README.md#用語)）には、独立したリポジトリの「認証 API」があった。その認証 API の中に、Keycloak（一般利用者の IdP。ID とパスワードを確かめてトークンを発行する）があった。このリポジトリにはまだ認証 API が無く、利用者はテストユーザー（alice / bob）だけで、増やすには Keycloak の管理コンソールを使うしかない。

この設計書は、認証 API をリポジトリ `auth` として足し、一般利用者が会員登録とパスワード変更を画面から行えるようにする。社員（Okta で認証する）のアカウントは扱わない。

次の表は、この変更の対象と規模、何ができれば完了かをまとめる。

| 項目 | 内容 |
|---|---|
| 対象 | 一般利用者（マイページ）のアカウント管理。社員（Okta で認証する。Okta は外部の SaaS で、アカウントはアプリの外で管理する）は対象外 |
| 発生規模 | リポジトリ 1 つの追加。全体を束ねる集約リポジトリ（このリポジトリ fullstack-lab）1 つと、画面 + BFF（画面専用のサーバー側 API。[用語](../architecture/README.md#用語)）、API（タスクの API）、認可 API（操作の可否を判定する API）、認証 API の領域（独立したリポジトリで作る単位）4 つになる。変えるリポジトリは、新規の `auth` と、`authz`、`web`、集約リポジトリの 4 つ。領域同士をつなぐ契約（OpenAPI の仕様）は、1 つを追加し、1 つを互換のまま変更する |
| 利用者への影響 | 一般利用者は自分でアカウントを作れず、パスワードも変えられない。テストユーザー（alice / bob）以外で試すには、開発者が Keycloak の管理コンソールで利用者を作る必要がある |
| 成功条件 | 未認証で会員登録画面を開いて登録し、そのままログインしてタスクを登録できる。ログイン後にパスワードを変え、新しいパスワードでログインし直せる。既存の認証（設計書 [0002](0002-authentication-authorization.md)）の経路は変わらない |

## 制約と前提

次の表は、この設計が従う制約と、成り立っているとして進める前提、不確かなまま置く仮定を分けて示す。

| 区分 | 内容 | 根拠 |
|---|---|---|
| 制約 | 認証 API は独立したリポジトリにし、Keycloak をその中に置く | 業務環境の事実（[architecture/ の「業務環境について聞いている事実」](../architecture/README.md#業務環境について聞いている事実)。作成者 ht-0328 が 2026-10-28 に確かめた） |
| 制約 | 社員のアカウントは扱わない | Okta は外部の SaaS で、アカウント管理はアプリの外にある |
| 制約 | 領域同士は契約（OpenAPI）と、契約から生成して publish（Maven リポジトリに登録して配布）した成果物だけでつなぐ | 設計書 [0003](0003-contracts-and-repositories.md)、[ADR-0002 領域間のクライアントは成果物（Maven）として配布し、ソースを共有しない](../adr/ADR-0002-distribute-clients-as-artifacts.md) |
| 前提 | ログインは引き続き前段（アプリより手前で認証とセッションを担う層。ローカルは oauth2-proxy、AWS では ALB の認証アクション。ALB は AWS のロードバランサー）が Keycloak のログイン画面へ誘導する | 設計書 [0002](0002-authentication-authorization.md) |
| 前提 | BFF（JWT を検証し、認可 API と API を呼ぶ）が受け取る JWT（IdP が署名して発行するトークン）の `sub`（利用者を一意に示すクレーム）は Keycloak のユーザー ID（本文では利用者 ID と呼ぶ）である | Keycloak は、発行するトークンの `sub` にユーザー ID を入れる |
| 仮定 | 認証 API の責務は「Keycloak のユーザー管理の代行」（登録、プロフィール参照、パスワード変更）とし、ログインは担当しない | 業務環境の認証 API が何を担っていたかは記録が無く、確かめられない。前段の認証と重ならない範囲に絞る。[構成の仮定 12](../architecture/README.md#仮定) |
| 仮定 | Keycloak の設定のうち、realm `customer`（一般利用者）は `auth` リポジトリに、realm `staff`（Okta の代替）は集約リポジトリに置く | 業務環境で Keycloak の設定をどう分けていたかは不明。「認証 API の中に Keycloak があった」という事実に合わせ、業務環境に無い realm `staff` は集約リポジトリに残す。[構成の仮定 14](../architecture/README.md#仮定) |
| 仮定 | 認証 API は内部ネットワーク専用で、BFF を信頼し、自分では呼び出し元を認証・認可しない | 業務環境の認証 API がどう守られていたかは不明。API と同じ扱い（[構成の仮定 7](../architecture/README.md#仮定)）にそろえる。認証 API に広げるのはこの変更だけの判断で、構成の仮定には載せない |
| 仮定 | 会員登録の画面と API は未認証で到達できる公開パスとし、入口（すべてのリクエストを最初に受けて振り分けるもの。ローカルは Nginx、AWS では ALB）が認証なしで転送する | ALB ではリスナールール単位で認証アクションを付けないことができる。[構成の仮定 13](../architecture/README.md#仮定) |
| 仮定 | メールアドレスの確認（確認メール）は行わない | ローカルにメール送信の仕組みが無い。登録時に `emailVerified = true` で作る。業務環境でどうしていたかは不明で、この変更だけの判断として構成の仮定には載せない |

## 採用案

認証 API を Keycloak の Admin REST API（ユーザーの作成や更新を行う管理用 API。以下 Admin API）の窓口として置き、BFF はアカウントの操作を認証 API 経由でだけ行う。

次の表は、採用案を要素ごとに分け、採用内容と責務を示す。

| 要素 | 採用内容 | 責務 |
|---|---|---|
| リポジトリ `auth` | Kotlin + Spring Boot。`api` / `authz` と同じ構成にする。契約からコードを生成して git で管理し（[ADR-0003 OpenAPI から生成したコードは git で管理する](../adr/ADR-0003-commit-generated-code.md)）、成果物 `auth-client`（契約から生成したクライアントのライブラリ）を publish し、Karate（API のテスト）を `compose.test.yaml` で実行する | 認証 API と、Keycloak の realm（利用者とクライアントをまとめる区画）`customer` の定義（`auth/keycloak/import/customer-realm.json`） |
| 認証 API | `POST /auth/v1/customers`（登録）、`GET /auth/v1/customers/{id}`（参照）、`PUT /auth/v1/customers/{id}/password`（変更） | Keycloak の Admin API を呼び、入力の検証とエラーの変換（409 / 403 / 404）を行う。内部ネットワーク専用で、BFF を信頼する（「制約と前提」の仮定） |
| Keycloak のクライアント `auth-api` | 機密クライアント（シークレットを持つ OAuth クライアント）にする。サービスアカウント（利用者を介さずに自分の権限でトークンを得る仕組み）を有効にし、`realm-management` のロール `manage-users`、`view-users`、`view-realm`（ロール ID の取得に使う）を付ける。現在のパスワードの確認に使うため、Direct Access Grants（ID とパスワードを直接送ってトークンを得るフロー）も有効にする | 認証 API だけが使う。シークレットは `AUTH_API_CLIENT_SECRET` |
| realm `staff` | 集約リポジトリに残す（`keycloak/import/staff-realm.json`）。Okta の代替であり、業務環境には存在しない学習用の設定 | 社員のログイン（Okta の代替）。認証 API は関与しない |
| BFF | `POST /bff/signup`（未認証で呼べる）、`PUT /bff/me/password`（認証済み。`sub` を利用者 ID にして認証 API を呼ぶ）、`GET /bff/me` の `capabilities.canChangePassword`（画面にパスワード変更の導線を出すかどうか。出し分け用で、守りは BFF と認可 API が担う） | 認証 API の成果物 `auth-client` を使う。パスワード変更の前に認可 API へ `account:change-password` を問い合わせる |
| 認可 API | `customer-actions`（一般利用者に、自分のリソースに限って許可する操作の一覧）に `account:change-password` を追加 | 一般利用者は自分のアカウントにだけ許可。社員はどのロールにも付与しないので拒否（Okta 側で管理するため） |
| 画面 | `/signup`（公開。登録後にログインへの導線）、`/me/password`（一般利用者のみ表示） | ブラウザから同一オリジンの `/bff/*` を呼ぶ。SSR（サーバー側描画。画面のフレームワーク Nuxt のサーバーが HTML を組み立てる）では BFF の 401 を「未認証」として扱い、公開ページを描画する |
| 入口（Nginx） | 一般利用者のホストだけ、`/signup`、`/bff/signup`、`/_nuxt/`（画面の静的アセット。公開ページの描画に必要）を `auth_request`（Nginx が前段に認証の有無を問い合わせる仕組み）なしで転送する。転送時に `X-Amzn-Oidc-*` ヘッダー（認証済みの利用者の ID とトークンを後段に渡すヘッダー。ALB が付けるものと同じ名前）を空にし、利用者が偽のヘッダーを付けて認証済みを装うのを防ぐ。AWS では ALB のリスナールール（パス条件、認証アクションなし）に相当する。社員のホストには公開パスを作らない（設定は `nginx/snippets/public-locations.conf`） | 公開パスの転送と、偽の認証ヘッダーの除去 |

### 影響するリポジトリ

次の表は、リポジトリごとに変更の有無と内容を示す。変えないリポジトリにも理由を書く。

| リポジトリ | 変更 | 変えない理由 |
|---|---|---|
| `auth`（新規 `fullstack-lab-auth`） | 認証 API 本体、契約 `openapi/auth.yaml`、成果物 `auth-client`、Keycloak の realm `customer` の定義、Karate | — |
| `authz` | `application.yml` の `customer-actions` に `account:change-password` を追加。Karate に判定を追加 | 契約（`openapi/authz.yaml`）と判定ロジック（`Policy`）は変えない。操作名は自由文字列なので、設定（`application.yml`）に 1 行足せば済むため |
| `web` | BFF: `auth-client` への依存、`/bff/signup`（公開）と `/bff/me/password`、`Capabilities.canChangePassword`。画面: `/signup` と `/me/password`。Playwright（画面のテスト） | — |
| 集約 | サブモジュール `auth/` の追加、Compose（`auth` サービス、Keycloak の realm の取り込み元）、Nginx の公開パス、スモークテスト、Swagger UI（契約を画面で読み、試せるツール）、スクリプト（`scripts/` の `generate.sh`、`publish-clients.sh`、`unit-test.sh`、`api-test.sh`、`smoke-test.sh` に `auth` を追加）、ドキュメント（[README](../../README.md)、[architecture/](../architecture/README.md)） | — |
| `api` | なし | 業務データ（タスク）は変わらない。利用者の識別は引き続き JWT の `sub` |

### 契約の変更

次の抜粋は、新規の契約 `auth/openapi/auth.yaml`（1.0.0）のエンドポイントとスキーマを示す。

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

次の抜粋は、`web/openapi/bff.yaml` を 1.0.0 から 1.1.0 に上げる差分を示す。追加だけなので互換（既存の呼び出し側はそのまま動く）である。

```yaml
paths:
  /bff/signup:         post: SignupInput → 201 SignupResult / 400 / 409
  /bff/me/password:    put:  ChangePasswordInput → 204 / 400 / 401 / 403
components:
  schemas:
    Capabilities: { canCreateTask, canChangePassword }   # canChangePassword を追加
```

`authz/openapi/authz.yaml` は変えない。操作名は自由文字列なので、新しい操作を足しても契約は変わらないため。

### 認可

次の表は、この変更で増える操作ごとに、利用者の種別による可否を示す。一般利用者は所有者かどうかで、社員はロールで決まる。

| 操作 | 一般利用者 | 社員 | 備考 |
|---|---|---|---|
| 会員登録 | 未認証で可 | 該当しない。社員のアカウントは Okta 側で作るため | 主体（操作する利用者）が無いので認可 API に問い合わせない。乱用対策（レート制限、CAPTCHA）は含めない（「課題・申し送り事項」参照） |
| `account:change-password` | 自分のアカウントのみ許可 | 拒否 | `authz/src/main/resources/application.yml` の `customer-actions` に追加。`staff-role-permissions`（社員のロールごとに許可する操作）には追加しない |

### リクエストの流れ（会員登録）

次の手順は、未認証の利用者が会員登録してからログインするまでに、リクエストがどの順でどこを通るかを示す。

1. ブラウザのリクエストが、入口（Nginx）の `/signup`（認証なし）→ Nuxt（SSR）の順に流れる。`app.vue`（すべての画面に共通する外枠）が呼ぶ `/bff/me` は 401 になるので、画面は「未認証」として描画する
2. ブラウザのリクエストが、入口（Nginx）の `/bff/signup`（認証なし）→ BFF → 認証 API `POST /auth/v1/customers` → Keycloak の Admin API の順に流れる。Keycloak でユーザー作成、パスワード設定、ロール `customer` の付与を行う
3. 画面が「ログインする」への導線（`/oauth2/start?rd=/`）を出し、以降は設計書 [0002](0002-authentication-authorization.md) の流れでログインする

### テスト

次の表は、層ごとに何を確かめるかを示す。認可の守りは画面の導線の有無ではなく、直接呼んで拒否されることで確かめる。

| 層 | 対象 | 確かめること |
|---|---|---|
| 単体（`auth`） | Keycloak の Admin API の呼び出し（Spring の MockRestServiceServer で Keycloak を模擬する） | トークン取得と使い回し、ユーザー作成とロール付与の順序、ロール付与に失敗したときのユーザーの削除。Keycloak の応答（メールアドレスの重複 409、未知の ID 404、現在のパスワードの誤りを示す `invalid_grant`）を、認証 API がそれぞれ 409、404、403 で返す例外に変えること。新しいパスワードを現在のパスワードの確認に送らないこと |
| 単体（`web/bff`） | 認証 API と認可 API の呼び出し | 社員のパスワード変更のリクエストは認可 API で拒否して認証 API を呼ばない。`sub` を利用者 ID に使う |
| Karate（`auth`） | 実際の Keycloak を `compose.test.yaml` で立てる | 利用者を登録して参照し、同じメールアドレスでの再登録は 409 になる。パスワード変更は、現在のパスワードが違えば 403、正しければ 204 になり、そのあと新しいパスワードでトークンが取れる。入力エラーは 400、未知の ID は 404 になる |
| Karate（`authz`） | 判定表 | 一般利用者の `account:change-password`（本人 / 他人）、社員の拒否 |
| Playwright（`web/e2e`） | 画面 | 利用者が登録、ログイン、タスク登録、パスワード変更、ログアウトの順に操作し、新しいパスワードでログインし直せる。社員にはパスワード変更の導線が出ない |
| スモーク（集約） | 入口 | 未認証で `/signup` と `/bff/signup` に到達できる。社員のホストには公開パスが無いので、`/signup` はログインへリダイレクトされる（302）。公開パスに付けた偽の `X-Amzn-Oidc-*` は捨てられる。`/bff/me/password` は未認証で 401 になる |

## 比較した代替案とトレードオフ

次の表は、検討した案を採用案も含めて並べ、採否の理由を示す。

| 案 | 利点 | 欠点 | 採否の理由 |
|---|---|---|---|
| 認証 API を独立リポジトリに置き、Keycloak の Admin API の窓口にする（採用） | 業務環境の境界と同じ。アカウント操作の入口が 1 つになり、Keycloak の都合（API の形、エラー）を BFF から隠せる | リポジトリと成果物（`auth-client`）が増える | 業務環境の事実（認証 API が独立したリポジトリにあった）に合わせる |
| Keycloak の登録画面（`registrationAllowed`）とアカウントコンソールを使う | 実装がほぼ不要 | 認証 API の再現にならない。画面の見た目と導線が Keycloak 任せになる | 不採用。業務環境の認証 API を再現することが目的で、Keycloak の画面に任せると再現にならないため |
| BFF が Keycloak の Admin API を直接呼ぶ | リポジトリが増えない | 認証 API が独立していたという事実に反する。BFF が Keycloak の管理権限を持つ | 不採用。欠点に挙げた 2 点（業務環境の事実に反する、BFF が Keycloak の管理権限を持つ）を避けるため |
| 認証 API がログイン（ID とパスワードからトークン発行）も担う | 画面でログインを完結できる | 前段（ALB）の認証と二重になり、設計書 [0002](0002-authentication-authorization.md) の経路を作り直すことになる | 不採用。業務環境の認証 API の責務が不明なので、既存の経路を壊さない範囲に絞る |

## 失敗時の動作

次の表は、失敗の条件ごとに、どう検知し、システムがどう動き、利用者にどう見えるかを示す。認証 API の失敗は会員登録とパスワード変更だけに影響し、ログインとタスクの操作は止めない。

| 失敗条件 | 検知方法 | システムの動作 | 利用者への影響 |
|---|---|---|---|
| Keycloak に到達できない | 認証 API の Admin API 呼び出しが失敗する | 認証 API は、IdP に到達できないことを 503 で示す。BFF は内部の情報を画面に出さないため、上流（認証 API）の 5xx と接続失敗をまとめて 502 で返す | 登録・変更ができない。ログイン済みの利用者のタスク操作には影響しない |
| メールアドレスが登録済み | Keycloak が 409 を返す | 認証 API は 409 を Problem Details（RFC 9457 のエラー応答の形式）で返す。BFF はそのまま返す | 画面に「このメールアドレスは登録済みです」と表示する |
| 現在のパスワードが違う | Keycloak のトークン発行が `invalid_grant` を返す | 認証 API は 403 を返す。BFF はそのまま返す | 画面に「現在のパスワードが違います」と表示する。回数制限は Keycloak の既定（無効）のままにする（「課題・申し送り事項」参照） |
| 認証 API が停止している | BFF の呼び出しが失敗する | BFF は 502 を返す | 登録・変更ができない |
| ユーザー作成後のロール付与に失敗する | 認証 API の Admin API 呼び出しがエラーを返す | 認証 API は作成したユーザーを削除してから 503 を返す（登録は成功か失敗のどちらかにする） | 登録をやり直せる |

## 技術観点の確認

該当しない観点も行を残し、セルに該当しない理由を書いている（[docs の決まり](../README.md#形式の決まり)の F-3）。

### セキュリティと権限

次の表は、セキュリティの観点ごとに、この変更での扱いを示す。

| 観点 | 内容 |
|---|---|
| 認証 | 認証 API は内部ネットワーク専用で、BFF を信頼する（API と同じ扱い）。認証 API は、Keycloak のクライアント `auth-api` のサービスアカウント（`manage-users`、`view-users`、ロール ID の取得に使う `view-realm`）で Keycloak に接続する。入口（Nginx）は公開パスでも `X-Amzn-Oidc-*` を空に上書きし、BFF は `/bff/signup` 以外を認証必須にする |
| 認可 | 認証 API 自身は認可しない。BFF が利用者 ID に `sub` を使い、他人のアカウントを指定できないようにする。パスワード変更は認可 API に問い合わせる |
| 秘密情報の保管 | `AUTH_API_CLIENT_SECRET` は `.env`（ローカル）/ Secrets Manager（AWS の秘密情報の保管サービス）に置く。パスワードはログと例外メッセージに出さない |
| 通信の暗号化 | ローカルは HTTP。AWS では VPC（AWS の中に作る閉じたネットワーク）内の通信（API / 認可 API と同じ） |
| 監査ログ | 登録と変更を利用者 ID とリクエスト ID で記録する（メールアドレスとパスワードは出さない） |

### データ

次の表は、データの観点ごとの扱いを示す。個人情報を保持するのは Keycloak だけである。

| 観点 | 内容 |
|---|---|
| 扱う個人情報 | メールアドレス、氏名、パスワード。保持するのは Keycloak だけで、アプリの DB には持たない |
| 保持期間と削除 | 退会（削除）は本設計の範囲外。「課題・申し送り事項」に送る |
| 移行 | 既存のテストユーザー（alice / bob）は realm の定義に残す。認証 API で作ったユーザーも同じ realm に入る |
| 容量の見込み | 学習用のため該当しない |

### 性能と可用性

学習用の構成なので、目標値は置かない。可用性については、認証 API は Keycloak の起動を待たずに起動し、Admin API 用のトークンは最初の呼び出し時に取得する。BFF が JWT 検証用の公開鍵を最初のリクエスト時に取る方針と同じである。

### 可観測性

次の表は、ログとメトリクスの扱いを示す。

| 観点 | 内容 |
|---|---|
| ログ | `X-Request-Id` を認証 API まで引き継ぐ（`RequestIdFilter`）。Keycloak のエラー応答はステータスだけを記録する |
| メトリクス、アラート | 学習用のため該当しない |

### 展開と後始末

次の表は、展開の順序と、展開後に戻す方法、互換性を示す。

| 観点 | 内容 |
|---|---|
| 展開手順 | `auth`（新規、publish）→ `authz`（設定）→ `web`（BFF の契約を 1.1.0 にし、`web/bff/gradle.properties` の `authClientVersion`（BFF が依存する `auth-client` のバージョン）を 1.0.0 にする）→ 集約（サブモジュール、Compose、Nginx）の順に展開する。順序はスキル [pr-and-commit](../../.agents/skills/pr-and-commit/SKILL.md) に従う |
| 切り戻し | 集約リポジトリの参照を前のコミットに戻す。`auth-client` 1.0.0 は残す |
| 互換性 | `bff.yaml` は追加のみ（互換）。`authz.yaml` は変えない。realm `customer` の定義は置き場所が変わるだけで内容は互換（Keycloak のクライアント `auth-api` の追加のみ） |
| 廃止計画 | なし |

## 実装の段取り

実装済みのため該当しない。展開の順序は「展開と後始末」の「展開手順」の行に書いた。

## 未決事項

なし。2026-10-28 に作成者（ht-0328）が次の 2 点を決め、本文に反映した。

- 業務環境の認証 API の責務は確かめられなかったため、Keycloak のユーザー管理の代行と仮定した（「制約と前提」の仮定、[構成の仮定 12](../architecture/README.md#仮定)）
- 対象を API だけでなく画面まで含めることにし、会員登録画面（`/signup`）とパスワード変更画面（`/me/password`）を採用案に入れた

## 課題・申し送り事項

次の点は、この設計に含めないと決めたことと、既知の制約である。

- 会員登録の乱用対策（レート制限、CAPTCHA、メールアドレスの確認）は含めない
- 退会（アカウント削除）と、プロフィールの変更は含めない
- Keycloak の総当たり対策（Brute Force Detection）は既定の無効のままにする

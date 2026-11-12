# アカウントの登録（`POST /auth/v1/customers`）

この文書は、認証 API（[全体像](README.md)）の `POST /auth/v1/customers` の処理を記す。このエンドポイントは、一般利用者のアカウントを、Keycloak（一般利用者のログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）に作る。作るには、Keycloak の Admin REST API（Keycloak のユーザーの作成や更新を行う管理用の API。以下 Admin API）を呼ぶ。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [auth.yaml](../../../auth/openapi/auth.yaml) にあるので、この文書には書き写さない。

この文書では、アプリを使う人を「利用者」、Keycloak に登録されたアカウントを「Keycloak のユーザー」と書き分ける。realm は、Keycloak の中で、Keycloak のユーザーとクライアントをまとめる区画である。

流れは [全体像の「アカウントの登録」](README.md#アカウントの登録) の図にある。入力が不正なときは、認証 API は Keycloak を呼ばずに 400 を返す。

## 処理と応答

認証 API は、入力を検証し、Keycloak のユーザーを作り、realm ロール `customer`（一般利用者を示すロール。[realm `customer` の定義](keycloak-realm-customer.md)）を付ける。次の表は、応答を示す。エラーの形と、Keycloak の失敗の扱いは [エラー応答](error-responses.md) にある。

| 場合 | 応答 |
|---|---|
| 登録できた | 201 と登録したアカウント。`id` は Keycloak のユーザーの ID |
| 入力が不正 | 400 |
| メールアドレスが登録済み | 409 |

Keycloak のユーザーの ID は、利用者がログインしたあとの JWT（Keycloak が署名して発行するトークン。[用語](../../architecture/README.md#用語)）の `sub` と同じ値である。

## 入力の検証

入力の決まり（必須かどうか、文字数、メールアドレスの形）は契約 auth.yaml にあり、契約から生成したコードが検証する。

## Admin API の呼び出しごとの値と条件

Keycloak のユーザーを作る呼び出しと、ロールを付ける呼び出しは別である。そのため認証 API は、ロールを付けられなかったときに作った Keycloak のユーザーを消し、ロールの無い Keycloak のユーザーを残さないようにしている。Admin API を呼ぶためのトークンは [Admin API 用のトークン](keycloak-admin-token.md) に、接続先とタイムアウトは [Keycloak への接続の設定](keycloak-connection.md) にある。

次の表は、呼び出しごとに、全体像の図に無い値と条件を示す。

| 呼び出し | 値と条件 |
|---|---|
| `POST /admin/realms/{realm}/users` | ユーザー名とメールアドレスの両方に `email` を入れ、有効、メールアドレスは確認済み、パスワードは一時的でないものとして作る。Keycloak が振った ID は、応答の `Location` ヘッダーの末尾から取る |
| `GET /admin/realms/{realm}/roles/customer` | realm ロール `customer` の定義（ID と名前）を取る |
| `DELETE /admin/realms/{realm}/users/{id}` | ロールの定義の取得か付与で、Keycloak がエラーの応答を返した、接続できない、応答がタイムアウトした、のどれかのときに呼ぶ。消したあと、元の失敗をエラーとして返す。消すことにも失敗したら、ログに記録するだけにする |

認証 API は、確認メールを送らない。付けるロールの名前は、`auth/src/main/resources/application.yml` の `auth.keycloak.customer-role` で決める。

## ログ

認証 API は、登録を、Keycloak のユーザーの ID とリクエストの ID でログに記録する。ログに出さないものは [エラー応答の「ログに出す内容」](error-responses.md#ログに出す内容) にある。

## テスト

次の表は、`auth` リポジトリの中で、登録について確かめることを示す。Karate は、API を HTTP で呼んで確かめるテストである。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `auth/src/test/` の `CustomerAccountServiceTest`（Keycloak の応答を Spring の MockRestServiceServer で再現する） | 登録での呼び出しの順と中身、重複の扱い、ロールを付けられないときの削除 |
| Karate | `auth/karate/features/customers.feature`（`auth/compose.test.yaml` で認証 API と Keycloak を起動して実行。Keycloak は realm `customer` の定義を取り込む） | 登録、重複の 409、入力の不正の 400。登録した Keycloak のユーザーで Keycloak からトークンを取ると、`sub` が登録の `id` と同じで、ロール `customer` が入っていること |

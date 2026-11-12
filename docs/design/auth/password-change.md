# パスワードの変更（`PUT /auth/v1/customers/{id}/password`）

この文書は、認証 API（[全体像](README.md)）の `PUT /auth/v1/customers/{id}/password` の処理を記す。このエンドポイントは、一般利用者のアカウントの現在のパスワードを確かめてから、新しいパスワードに変える。アカウントは、Keycloak（一般利用者のログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）に登録されたアカウントで、この文書では「Keycloak のユーザー」と書く。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [auth.yaml](../../../auth/openapi/auth.yaml) にあるので、この文書には書き写さない。

流れは [全体像の「パスワードの変更」](README.md#パスワードの変更) の図にある。入力が不正なときは、認証 API は Keycloak を呼ばずに 400 を返す。

## 処理と応答

認証 API は、入力を検証し、現在のパスワードを Keycloak で確かめてから、新しいパスワードに変える。次の表は、応答を示す。エラーの形と、Keycloak の失敗の扱いは [エラー応答](error-responses.md) にある。

| 場合 | 応答 |
|---|---|
| 変更できた | 204（本文なし） |
| 入力が不正 | 400 |
| Keycloak のユーザーが無い | 404 |
| 現在のパスワードが違う | 403 |

## 入力の検証

入力の決まり（必須かどうか、文字数）は契約 auth.yaml にあり、契約から生成したコードが検証する。認証 API は、新しいパスワードが現在のパスワードと同じかどうかを確かめない。

## Keycloak の呼び出しごとの値と条件

Keycloak の Admin REST API（Keycloak のユーザーの作成や更新を行う管理用の API。以下 Admin API）のパスワードの再設定は、現在のパスワードを確かめない。そのため認証 API が、変える前に現在のパスワードを確かめる。Admin API を呼ぶためのトークンは [Admin API 用のトークン](keycloak-admin-token.md) に、接続先とタイムアウトは [Keycloak への接続の設定](keycloak-connection.md) にある。`{realm}` は、Keycloak の中で Keycloak のユーザーとクライアントをまとめる区画の名前である。

次の箇条書きは、呼び出しごとに、全体像の図に無い値と条件を示す。

- 認証 API は、現在のパスワードの確認に、Keycloak から取ったユーザー名を使う（方法は「現在のパスワードの確認」の節）
- 認証 API は、`reset-password` で、`newPassword` を一時的でないパスワードとして設定する
- 認証 API は、現在のパスワードの確認では `newPassword` を Keycloak に送らない。確認で得たトークンは、確認にだけ使って捨てる

## 現在のパスワードの確認

認証 API は、現在のパスワードが正しいかを、そのパスワードでトークンを取れるかどうかで確かめる。使うのは Direct Access Grants（ユーザー名とパスワードを直接送ってトークンを得るフロー）である。送る先は、Keycloak のトークンエンドポイント（`/realms/{realm}/protocol/openid-connect/token`）である。

- 認証 API は、トークンエンドポイントに `grant_type=password`、クライアント `auth-api`（認証 API だけが使う Keycloak のクライアント。[realm `customer` の定義](keycloak-realm-customer.md)）の ID とクライアントシークレット、Keycloak のユーザーのユーザー名、現在のパスワードを送る
- Keycloak が 2xx を返したら、認証 API は現在のパスワードが正しいとみなす
- Keycloak が 400 か 401 を返し、応答の本文に `invalid_grant` があれば、認証 API は現在のパスワードが違うとみなす
- Keycloak が `invalid_grant` の無い 400 を返したら、認証 API は Keycloak が入力を拒んだものとして 400 を返す（[エラー応答](error-responses.md)）
- それ以外の 4xx（`invalid_grant` の無い 401 を含む）は、認証 API は想定外の応答として 502 を返す

## ログ

認証 API は、パスワード変更と、現在のパスワードの不一致を、Keycloak のユーザーの ID とリクエストの ID でログに記録する。ログに出さないものは [エラー応答の「ログに出す内容」](error-responses.md#ログに出す内容) にある。

## テスト

次の表は、`auth` リポジトリの中で、パスワード変更について確かめることを示す。Karate は、API を HTTP で呼んで確かめるテストである。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `auth/src/test/` の `CustomerAccountServiceTest`（Keycloak の応答を Spring の MockRestServiceServer で再現する） | 現在のパスワードが違えば再設定を呼ばず、確認には新しいパスワードを送らないこと |
| Karate | `auth/karate/features/customers.feature`（`auth/compose.test.yaml` で認証 API と Keycloak を起動して実行。Keycloak は realm `customer` の定義を取り込む） | 現在のパスワードが違うときの 403、変更の 204。変更後は新しいパスワードで Keycloak からトークンを取れ、古いパスワードでは取れないこと。無い ID の 404 |

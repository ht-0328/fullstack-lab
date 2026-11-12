# アカウントの参照（`GET /auth/v1/customers/{id}`）

この文書は、認証 API（[全体像](README.md)）の `GET /auth/v1/customers/{id}` の処理を記す。このエンドポイントは、ID で一般利用者のアカウントを 1 件返す。アカウントは、Keycloak（一般利用者のログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）に登録されたアカウントで、この文書では「Keycloak のユーザー」と書く。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [auth.yaml](../../../auth/openapi/auth.yaml) にあるので、この文書には書き写さない。

流れは [全体像の「アカウントの参照」](README.md#アカウントの参照) の図にある。

## 処理と応答

認証 API は、Keycloak の Admin REST API（Keycloak のユーザーの作成や更新を行う管理用の API。以下 Admin API）の `GET /admin/realms/{realm}/users/{id}` で Keycloak のユーザーを取り、ID、メールアドレス、姓、名だけを返す。`{realm}` は、Keycloak の中で Keycloak のユーザーとクライアントをまとめる区画の名前である。Admin API を呼ぶためのトークンは [Admin API 用のトークン](keycloak-admin-token.md) に、接続先とタイムアウトは [Keycloak への接続の設定](keycloak-connection.md) にある。

次の表は、応答を示す。エラーの形と、Keycloak の失敗の扱いは [エラー応答](error-responses.md) にある。

| 場合 | 応答 |
|---|---|
| Keycloak のユーザーがある | 200 とアカウント |
| Keycloak が 404 を返した | 404 |

## 欠けた項目の扱い

Keycloak のユーザーにメールアドレスが無ければ、認証 API はユーザー名を `email` として返す。姓か名が無ければ、空の文字列を返す。認証 API は、Keycloak のユーザーが realm ロール `customer`（一般利用者を示すロール。[realm `customer` の定義](keycloak-realm-customer.md)）を持つかどうかを確かめない。

## テスト

次の表は、`auth` リポジトリの中で、参照について確かめることを示す。Karate は、API を HTTP で呼んで確かめるテストである。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `auth/src/test/` の `CustomerAccountServiceTest`（Keycloak の応答を Spring の MockRestServiceServer で再現する） | 無い ID の扱い |
| Karate | `auth/karate/features/customers.feature`（`auth/compose.test.yaml` で認証 API と Keycloak を起動して実行） | 登録したアカウントの参照と、無い ID の 404 |

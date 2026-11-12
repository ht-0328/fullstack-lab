# Keycloak への接続の設定

この文書は、認証 API（[全体像](README.md)）が Keycloak に接続するための設定を記す。Keycloak は、一般利用者のログインを受け付けてトークンを発行するサービスである（[用語](../../architecture/README.md#用語)）。認証 API は、この設定で、Keycloak の Admin API（Keycloak に登録されたアカウントの作成や更新を行う管理用の API）とトークンエンドポイントの両方を呼ぶ。

## 設定の項目

次の表は、Keycloak への接続の設定を示す。値の出所は `auth/src/main/resources/application.yml` の `auth.keycloak` で、タイムアウトの既定値は `auth/src/main/kotlin/com/example/fullstacklab/auth/keycloak/KeycloakProperties.kt` にある。表のクライアントは、Keycloak にトークンを求めるアプリの登録で、realm は、Keycloak の中で、Keycloak に登録されたアカウントとクライアントをまとめる区画である。

| 項目 | 内容 |
|---|---|
| 接続先 | 環境変数 `KEYCLOAK_BASE_URL`（必須）。コンテナ間の URL を入れる |
| realm | 環境変数 `KEYCLOAK_REALM`。無ければ `customer` |
| クライアントの ID | 環境変数 `AUTH_API_CLIENT_ID`。無ければ `auth-api` |
| クライアントシークレット | 環境変数 `AUTH_API_CLIENT_SECRET`（必須）。値はリポジトリに置かない |
| タイムアウト | 接続 2 秒、読み取り 5 秒 |
| 失敗の扱い | 認証 API は再試行しない。エラーへの変換は [エラー応答](error-responses.md) にある |

クライアント `auth-api` の定義と、`AUTH_API_CLIENT_SECRET` を Keycloak の側に渡す方法は、[realm `customer` の定義](keycloak-realm-customer.md) にある。

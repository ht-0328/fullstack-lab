# Admin API 用のトークン

この文書は、認証 API（[全体像](README.md)）が Keycloak の Admin API を呼ぶためのトークンの扱いを記す。Keycloak は、一般利用者のログインを受け付けてトークンを発行するサービスである（[用語](../../architecture/README.md#用語)）。Admin API は、Keycloak に登録されたアカウント（以下、Keycloak のユーザー）の作成や更新を行う管理用の API で、パスは `/admin/realms/{realm}/...` である。`{realm}` は、Keycloak の中で Keycloak のユーザーとクライアントをまとめる区画の名前である。

## 認証 API が呼ぶ Keycloak の API

認証 API は、Keycloak の 2 種類の API を呼ぶ。1 つは Admin API で、もう 1 つはトークンエンドポイント（`/realms/{realm}/protocol/openid-connect/token`）である。トークンエンドポイントは、この文書のトークンの取得と、[パスワードの変更](password-change.md) の現在のパスワードの確認に使う。

## トークンの取得と使い回し

Admin API を呼ぶには、権限を持つトークンが要る。認証 API は、Keycloak のクライアント（Keycloak にトークンを求めるアプリの登録）`auth-api` のサービスアカウント（Keycloak のユーザーのログインを介さず、クライアント自身の権限でトークンを得る仕組み）でトークンを取る。サービスアカウントに付けたロールは [realm `customer` の定義](keycloak-realm-customer.md) に、クライアントの ID とクライアントシークレットの渡し方は [Keycloak への接続の設定](keycloak-connection.md) にある。

次の図は、認証 API が Admin API を呼ぶたびに、トークンを取るか使い回すかを決める流れを示す。

```mermaid
flowchart TD
  start["認証 API が Admin API を呼ぼうとする"] --> has{"メモリにトークンがあるか"}
  has -->|"無い（起動後の最初の呼び出し）"| get["トークンエンドポイントに grant_type=client_credentials で求める"]
  has -->|"ある"| exp{"期限まで 30 秒以上あるか"}
  exp -->|"30 秒を切った"| get
  exp -->|"ある"| call["Authorization: Bearer ヘッダーに付けて Admin API を呼ぶ"]
  get --> keep["取ったトークンをメモリに持つ"]
  keep --> call
```

次の箇条書きは、図に無い値と条件を示す。

- 認証 API は、トークンエンドポイントに、`grant_type=client_credentials` と合わせてクライアントの ID とクライアントシークレットを送る
- 認証 API が起動時にトークンを取らないので、Keycloak が起動していなくても認証 API は起動する（[稼働の確認](health.md)）
- 認証 API は、トークンの期限を、トークンエンドポイントの応答の `expires_in` で知る。realm `customer` のアクセストークンの期限は 300 秒である（[realm `customer` の定義](keycloak-realm-customer.md)）
- 取り直しの境目の 30 秒という値は、`auth/src/main/kotlin/com/example/fullstacklab/auth/keycloak/KeycloakAdminClient.kt` にある

## テスト

次の表は、`auth` リポジトリの中で、トークンについて確かめることを示す。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `auth/src/test/` の `CustomerAccountServiceTest`（Keycloak の応答を Spring の MockRestServiceServer で再現する） | Admin API 用のトークンの取得と使い回し |

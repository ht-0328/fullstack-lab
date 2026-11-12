# Keycloak のコンテナ

この文書は、ローカル環境で IdP（ログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）として動かす Keycloak のコンテナの作りを記す。Keycloak は 1 つのコンテナで、一般利用者用の realm `customer` と、社員用の realm `staff` の 2 つを持つ。realm は、Keycloak の中で、Keycloak のユーザーとクライアントをまとめる区画である。設定は、集約リポジトリの `compose.yaml` のサービス `keycloak` にある。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## 起動と realm の取り込み

Keycloak は、開発モード（`start-dev`）で起動し、起動時に realm の定義のファイルを取り込む。開発モードなので、コンテナを作り直すと、登録した Keycloak のユーザーは初期の状態に戻る。次の表は、取り込むファイルを示す。定義のファイルを 2 つのリポジトリに分けて置くのは、学習用の仮定である（[仮定 14](../../architecture/README.md#仮定)）。

| realm | 定義のファイル | 定義の文書 |
|---|---|---|
| `customer` | `auth/keycloak/import/customer-realm.json`（`auth` リポジトリにある） | [Keycloak の realm `customer` の定義](../auth/keycloak-realm-customer.md) |
| `staff` | `keycloak/import/staff-realm.json`（集約リポジトリにある） | [Keycloak の realm `staff` の定義](keycloak-realm-staff.md) |

定義のファイルは、環境ごとに変わる値と秘密の値を `${名前}` の形で書く。Keycloak は、取り込むときに、同じ名前の環境変数の値に置き換える。秘密の値は `.env` に置き、リポジトリには入れない。アプリの URL（`CUSTOMER_APP_URL`、`STAFF_APP_URL`）は、`compose.yaml` が `NGINX_HOST_PORT` から組み立てて渡す。

## 2 つの URL

同じ Keycloak を、ブラウザとコンテナが別の URL で呼ぶ。ブラウザはコンテナの名前 `keycloak` を解決できず、コンテナの中の `localhost` はそのコンテナ自身を指すためである。次の表は、2 つの URL を示す。

| 呼ぶ側 | URL | 使う場面 |
|---|---|---|
| ブラウザ | `http://localhost:8180`（ポートは環境変数 `KEYCLOAK_HOST_PORT` で変えられる） | ログイン画面。トークンの発行元 `iss` もこの URL になる |
| コンテナ | `http://keycloak:8080` | トークンの交換、公開鍵の取得、ログアウト、Admin API の呼び出し |

Keycloak は、`KC_HOSTNAME` にブラウザから見た URL を設定し、`KC_HOSTNAME_BACKCHANNEL_DYNAMIC` を有効にして、コンテナ間の URL での呼び出しも受け付ける。呼ぶ側の設定は、[前段（oauth2-proxy）](oauth2-proxy.md)、[JWT の検証](../web/jwt-verification.md)、[Keycloak への接続の設定](../auth/keycloak-connection.md) にある。

## 稼働の確認

Compose のヘルスチェックは、Keycloak の管理用のポート 9000 の `/health/ready` が `UP` を返すことで、Keycloak の稼働を確かめる。`docker compose up --wait` は、これが通るまで待つ。Keycloak の起動を待つサービスは無く、前段の oauth2-proxy、BFF、認証 API のどれも Keycloak を待たずに起動する（[Docker Compose のサービス](compose-services.md)）。

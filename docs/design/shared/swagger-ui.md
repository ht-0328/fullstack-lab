# Swagger UI

この文書は、契約（領域同士の API の取り決め。各領域の `openapi/*.yaml`。[用語](../../architecture/README.md#用語)）をブラウザで読むための Swagger UI の置き方を記す。Swagger UI は、OpenAPI の仕様を画面で読み、試せるツールである。開発者は、ローカル環境の `/swagger/` で、各領域の契約を 1 つの画面で見られる。設定は、集約リポジトリの `compose.yaml` のサービス `swagger-ui` にある。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## 見られる契約

次の表は、Swagger UI に渡す契約と、画面から実行できるかどうかを示す。契約のファイルは、各領域の `openapi/` から読み取り専用で渡すので、契約を変えると Swagger UI にもそのまま出る。

| 契約 | 画面からの実行 |
|---|---|
| `web/openapi/bff.yaml` | できる。BFF は同じオリジンにあるので、ログイン済みのセッションのまま呼べる。最初に表示する契約である |
| `api/openapi/api.yaml` | 読むだけ。API は入口から届かない |
| `authz/openapi/authz.yaml` | 読むだけ。認可 API は入口から届かない |
| `auth/openapi/auth.yaml` | 読むだけ。認証 API は入口から届かない |

## 認証

Swagger UI は、入口（すべてのリクエストを最初に受けて振り分ける Nginx。[用語](../../architecture/README.md#用語)）の背後に置く。入口が認証を確かめるので、Swagger UI はログインのあとにだけ開ける。未認証のときは、入口がログインへ移す（[入口（Nginx）のホストとパスの振り分け](nginx-routing.md)）。

## 確認の方法

未認証ではログインへ移ること、ログインのあとは開けること、契約のファイルが配信されることは、[スモークテスト](smoke-test.md) の「OpenAPI 仕様」のまとまりで確かめる。

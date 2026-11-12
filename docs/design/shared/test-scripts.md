# テストを実行するスクリプト

この文書は、集約リポジトリの `scripts/` にある、テストを実行するスクリプトを記す。どのスクリプトも Docker の中でテストを動かすので、ホストに JDK、Node.js、ブラウザは要らない。スモークテストは [スモークテスト（`scripts/smoke-test.sh`）](smoke-test.md) に、生成と publish のスクリプトは [契約からのコード生成](code-generation.md) と [生成クライアントの publish と取得](client-distribution.md) にある。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## スクリプトの一覧

次の表は、スクリプトごとに、実行するテストと、先に済ませておくことを示す。Karate は API を HTTP で呼んで確かめるテスト、Playwright はブラウザを操作して画面を確かめるテストである。

| スクリプト | 実行するテスト | 先に済ませておくこと |
|---|---|---|
| `scripts/unit-test.sh` | `api`、`authz`、`auth`、`web/bff` の単体テストと、`web/frontend` の型チェック。各 Dockerfile の `test` ステージか `typecheck` ステージをビルドして実行する | `./scripts/publish-clients.sh`。BFF が publish 済みのクライアントに依存するため |
| `scripts/api-test.sh` | `api`、`authz`、`auth` の Karate。起動中の Compose のネットワークの中から、各サービスを直接呼ぶ | `docker compose up -d --build --wait` |
| `scripts/e2e-test.sh` | `web/e2e` の Playwright。入口を通して、一般利用者用のホスト名と社員用のホスト名の両方を開く | `docker compose up -d --build --wait` |

`scripts/unit-test.sh` が使う `test` と `typecheck` のステージは、先に生成コードの検査を行う（[生成コードの検査（`check-generated`）](check-generated.md)）。

## 領域のリポジトリだけでの実行

領域の各リポジトリは、集約リポジトリが無くても、同じテストを実行できる。Karate は、各リポジトリの `compose.test.yaml` が、そのサービスと依存するものだけを起動して実行する。何を確かめるかは、各フォルダの文書の「テスト」の節にある。

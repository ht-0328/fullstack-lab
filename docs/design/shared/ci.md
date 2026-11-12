# 集約リポジトリの CI

この文書は、集約リポジトリ（領域のリポジトリを git submodule で束ねるリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）の CI が実行することを記す。CI は GitHub Actions で動き、定義は `.github/workflows/ci.yml` にある。領域の各リポジトリの CI は自分のリポジトリだけを確かめ、集約リポジトリの CI は、サブモジュールを含めた全体が動くことを確かめる。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## 実行される場面

CI は、PR と、main への push で実行される。集約リポジトリの main へは、PR を出し、CI が通ってからマージする（決まりは [AGENTS.md の「絶対厳守」](../../../AGENTS.md#絶対厳守)）。

## 実行すること

次の表は、CI が順に実行する段を示す。どれかが失敗すると、CI は Compose の状態とログを出力する。CI は、成功しても失敗しても、最後に Compose を止めてボリュームを消す。

| 順 | 段 | 内容 |
|---|---|---|
| 1 | 取得 | サブモジュールを含めてチェックアウトする |
| 2 | 設定 | `.env.example` を `.env` に写し、`admin.localhost` を `127.0.0.1` に向ける |
| 3 | クライアントの publish | `./scripts/publish-clients.sh` で、クライアントを Compose の中の Reposilite へ publish する（[生成クライアントの publish と取得](client-distribution.md)） |
| 4 | 起動 | `docker compose up -d --build --wait` で、全サービスのヘルスチェックが通るまで待つ（[Docker Compose のサービス](compose-services.md)） |
| 5 | スモークテスト | `./scripts/smoke-test.sh`（[スモークテスト](smoke-test.md)） |
| 6 | API のテスト | `./scripts/api-test.sh`（[テストを実行するスクリプト](test-scripts.md)） |
| 7 | 画面のテスト | `./scripts/e2e-test.sh`（[テストを実行するスクリプト](test-scripts.md)） |

集約リポジトリの CI は、秘密の値を使わない。`.env.example` のダミーの値だけで全体が起動するためである。

## 領域のリポジトリの CI との分担

次の表は、リポジトリごとの CI の分担を示す。クライアントの publish と取得の仕組みは [生成クライアントの publish と取得](client-distribution.md) にある。

| リポジトリ | CI が実行すること |
|---|---|
| `api`、`authz`、`auth` | 単体テストと Karate。main に取り込まれたときに、クライアントを GitHub Packages へ publish する |
| `web` | 画面の型チェックと、BFF の単体テスト。BFF は、publish 済みのクライアントを GitHub Packages から取得する |
| `infra` | [infra リポジトリの CI](../infra/infra-ci.md) |
| 集約リポジトリ | この文書の「実行すること」の節 |

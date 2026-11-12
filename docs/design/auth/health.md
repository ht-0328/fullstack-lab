# 稼働の確認（`GET /actuator/health`）

この文書は、認証 API（一般利用者のアカウントの登録、参照、パスワード変更を行う API。[全体像](README.md)）が動いているかを確かめるエンドポイントと、起動時の動作を記す。

## 処理と応答

認証 API は、稼働の確認用に `GET /actuator/health` を公開し、動いていれば 200 を返す。`auth/src/main/resources/application.yml` は、管理用のエンドポイントのうち `health` だけを公開し、`readiness` と `liveness` の確認を有効にしている。Compose のヘルスチェックは、`/actuator/health/readiness` が成功を返すことで、認証 API の稼働を確かめる。

## 起動時の動作

認証 API は、起動時には Keycloak（一般利用者のログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）を呼ばない。そのため、Keycloak が起動していなくても認証 API は起動する。Keycloak を最初に呼ぶのは、[Admin API 用のトークン](keycloak-admin-token.md) を取るときである。

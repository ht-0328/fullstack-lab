# 道具のコンテナ

道具のコンテナは、AWS CLI（AWS をコマンドで操作する公式の道具）と Terraform（AWS の構成をコードで書いて作る道具）を入れたコンテナである。開発者は、手元（開発者が作業する PC。[用語](../../architecture/README.md#用語)）のホスト（コンテナを動かす側の環境）にこの 2 つを入れず、このコンテナの中で動かす。この文書は、コンテナの作りを記す。コンテナで動かす決まりと理由は [ADR-0005](../../adr/ADR-0005-infra-tools-container.md) にある。

このフォルダの全体と、使う語の意味は [インフラの全体像](README.md) にある。

## 置き場所と起動の方法

道具のコンテナの定義は、`infra/Dockerfile`、`infra/compose.yaml`、`infra/.dockerignore` にある。開発者は、`infra/` で `docker compose run --rm tools` を打ってコンテナの中のシェルに入り、`aws login --remote` や `terraform plan` を公式の文書どおりに打つ。ログインの方法は [AWS へのログイン](aws-login.md) にある。

## コンテナの作り

次の表は、道具のコンテナの作りを示す。値の出所は `infra/Dockerfile` と `infra/compose.yaml` である。

| 項目 | 内容 |
|---|---|
| イメージ | 公式の `amazon/aws-cli` のイメージに、公式の `hashicorp/terraform` のイメージから取り出した Terraform を足す |
| バージョン | `infra/Dockerfile` の 2 つの `FROM` のタグで固定する。固定している値は AWS CLI 2.39.3、Terraform 1.17.1 である |
| バージョンの下限 | AWS CLI は 2.32.0 以上（`aws login` が使えるバージョン）。Terraform は 1.15.0 以上（下限の出所は [Terraform の state の置き場所の「`aws login` の認証情報を読めるバージョン」](terraform-state-bucket.md#aws-login-の認証情報を読めるバージョン)） |
| 動かすユーザー | ホストのユーザー（既定は UID 1000。違うときは環境変数 `HOST_UID` と `HOST_GID` で渡す）。コンテナが書いた `.terraform/` などの所有者を root にしないためである |
| 渡すディレクトリ | `infra/` をコンテナの `/work` に、ホストの `~/.aws` をコンテナの `/home/infra/.aws` に、どちらも書き込みできる形で渡す。`~/.aws` を書き込みできる形にするのは、AWS CLI が期限の近い認証情報を更新して書き戻すためである |
| リージョン | 環境変数 `AWS_REGION` に `ap-northeast-1` を入れる |

## 確認の方法

道具のイメージが作れることと、コンテナの中で 2 つの道具が動くことは、[infra リポジトリの CI](infra-ci.md) が確かめる。

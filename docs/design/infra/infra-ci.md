# infra リポジトリの CI

`infra` リポジトリの CI は、道具のコンテナ（AWS CLI と Terraform を入れたコンテナ。[道具のコンテナ](tools-container.md)）が作れることと、Terraform（AWS の構成をコードで書いて作る道具）のコードの形式と構文を確かめる。定義は `infra/.github/workflows/ci.yml` にある。CI は、PR と main への push で動き、AWS に接続しない。この文書は、CI の段ごとに確かめること、main の保護、CI が確かめないことを記す。

このフォルダの全体と、使う語の意味は [インフラの全体像](README.md) にある。

## 確かめること

次の表は、CI の段と、各段ですることを示す。最初の段は準備で、残りが確かめる段である。

| 段 | すること、確かめること |
|---|---|
| 手元と同じ前提をそろえる | コンテナを動かすユーザー（`HOST_UID`、`HOST_GID`）をランナーのユーザーに合わせ、空の `~/.aws` を用意する |
| 道具のイメージを作る | `infra/Dockerfile` からイメージが作れる |
| 道具のバージョン | コンテナの中で `aws --version` と `terraform version` が動く |
| Terraform の形式と構文 | `terraform fmt -check -recursive` が通る。`*.tf` のあるディレクトリごとに、`terraform init -backend=false`（state の置き場所につながずに初期化する）と `terraform validate` が通る |

「Terraform の形式と構文」の段は、`*.tf` のあるディレクトリを自分で探す。そのため、Terraform のディレクトリ（`infra/bootstrap` と `infra/shared`。[Terraform の state の置き場所](terraform-state-bucket.md)）が増えても、CI を変えなくてよい。`*.tf` のあるディレクトリが無ければ、この段の構文の検査は何も検査せずに通る。

## main の保護

`infra` リポジトリの main は、他のリポジトリと同じく PR と CI の成功を必須にする。

## 確かめないこと

CI は AWS に接続しないので、AWS に作ったリソースが Terraform のコードと合っているかは確かめない。これは、開発者が `apply` のあとの `plan` で確かめる（[Terraform の state の置き場所の「確認の方法」](terraform-state-bucket.md#確認の方法)）。

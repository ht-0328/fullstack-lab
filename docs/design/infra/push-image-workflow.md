# push 用のワークフロー

push 用のワークフローは、GitHub Actions（以下 Actions）で main のコミットのイメージをビルドし、ECR（AWS のコンテナイメージの置き場）に置く。領域（独立したリポジトリで作るアプリの単位。[用語](../../architecture/README.md#用語)）の各リポジトリ（`web`、`api`、`authz`、`auth`）の `.github/workflows/push-image.yml` に置く。この文書は、ワークフローの作り、GitHub の Secret、失敗時の動作、確認の方法を記す。

流れは [全体像の「イメージの push」](README.md#イメージの-push) の図にある。

## push するイメージ

`web` のワークフローは `nuxt`（`web/frontend/Dockerfile`）と `bff`（`web/bff/Dockerfile`）の 2 つを、ほかの 3 つは同名の 1 つを push する。push する先の設定は [ECR のリポジトリ](ecr-repositories.md)にある。

## ワークフローの作り

次の表は、ワークフローの作りを示す。OIDC は、ここでは GitHub が発行するトークンで AWS の期限つきの認証情報を得る仕組みである（[用語](../../architecture/README.md#用語)）。

| 項目 | 内容 |
|---|---|
| 起動 | `workflow_dispatch`（Actions の画面の「Run workflow」）だけ。main へのマージでは起動しない |
| 認証 | `aws-actions/configure-aws-credentials`（OIDC でロールに切り替える公式のアクション）で、Secret `AWS_ROLE_ARN` のロールに切り替える。認証情報は、ジョブごとに期限つきで発行される |
| アカウント ID の扱い | ワークフローは、アカウント ID をログのマスク（伏せ字にする文字列）に登録する。アクションの入力 `mask-aws-account-id` を使う |
| ビルド | 各 Dockerfile の `runtime` ステージをビルドする |
| タグ | コミットの SHA（40 文字）。どのコミットのイメージかを一意に示し、タグの上書き不可と両立させるためである |
| 同じタグの扱い | ワークフローは、`ecr:DescribeImages` で同じタグが ECR にあるかを確かめ、あれば push せずに成功で終わる |

ロールの権限は [push 用の IAM ロール](ecr-push-role.md)にある。AWS の API の呼び出しと ECR への push は HTTPS で行う。

## 性能と可用性

性能と可用性の目標値は置かない。push は、人が手で起動するたびに 1 回だけ動くためである。ワークフローは、Gradle（ソースのコンパイルとテストをまとめて行うビルドツール）でのビルドを含むので、数分かかる。

## GitHub の Secret

開発者は、領域の各リポジトリの Secret `AWS_ROLE_ARN` に、そのリポジトリ用のロールの ARN を入れる。ARN は AWS のリソースを一意に指す名前で、アカウント ID を含む。Secret に置くのは、アカウント ID をワークフローのファイルに書かないためである。

## イメージの中身

イメージに秘密情報を含めない。BFF のビルドで使う GitHub Packages（CI で生成クライアントを置いている Maven リポジトリ）の資格情報は、`web` の CI と同じく build secret（ビルドの間だけ渡し、イメージに残さない値）で渡す。

## 失敗時の動作

次の表は、失敗の条件ごとの動作と、開発者がすることを示す。どれもアプリの利用者には影響しない。

| 失敗の条件 | 検知の方法 | 動作 | 開発者がすること |
|---|---|---|---|
| main 以外のブランチで push を起動した | `aws-actions/configure-aws-credentials` がロールへの切り替えで失敗する | ワークフローが失敗し、何も push しない | main を選んで起動し直す |
| `bff` のビルドで生成クライアントを取得できない | `docker build` が依存の解決で失敗する | 何も push しない | `api` / `authz` / `auth` のクライアントが、GitHub Packages に publish（[用語](../../architecture/README.md#用語)）済みかを確かめる |

## 確認の方法

次の表は、ワークフローの確認の方法を示す。どれも開発者が手で確かめる。このワークフローはアプリのコードを変えないので、アプリのテスト（単体テスト、API のテストの Karate、画面のテストの Playwright、スモークテスト）は変えずに通ればよい。

| 対象 | 確かめること |
|---|---|
| push | 開発者が main で「Run workflow」を押すと、コミットの SHA のタグで ECR にイメージが入る。同じコミットでもう一度押すと、push せずに成功する |
| ログ | ワークフローのログに、アカウント ID が出ていない |

main 以外のブランチで失敗することの確認の方法は、[push 用の IAM ロールの「確認の方法」](ecr-push-role.md#確認の方法)にある。

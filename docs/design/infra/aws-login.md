# AWS へのログイン

開発者は、手元（開発者が作業する PC。[用語](../../architecture/README.md#用語)）から AWS を操作するとき、`aws login`（マネジメントコンソールと同じ ID とパスワードで、期限つきの認証情報を得るコマンド）で認証する。長期のアクセスキー（期限の無い認証情報）は作らない。この文書は、ログインの方法、認証情報の置き場所と期限、認証で止まったときの扱いを記す。`aws login` を使う決まりと理由は [ADR-0005](../../adr/ADR-0005-infra-tools-container.md) にある。

流れは [全体像の「手元からのログインと Terraform の実行」](README.md#手元からのログインと-terraform-の実行) の図にある。

## ログインの方法

ログインは、開発者が[道具のコンテナ](tools-container.md)（AWS CLI と Terraform を入れたコンテナ）の中で `aws login --remote` を打って行う。サインインはホスト（コンテナを動かす側の環境）のブラウザで行い、所要は数分である。手順の詳細は [infra の README](../../../infra/README.md) にある。

開発者は、IAM（AWS の利用者と権限を管理するサービス）のユーザー `Administrator`（AWS のすべての操作を許されたユーザー。[architecture の「AWS アカウント」](../../architecture/README.md#aws-アカウント)）でログインする。Terraform（AWS の構成をコードで書いて作る道具）も、このユーザーで実行する。

## 認証情報の置き場所と期限

認証情報はホストの `~/.aws` に残るので、コンテナを出ても、イメージを作り直しても、ログインし直さなくてよい。認証情報の期限は、サインインから最大 12 時間（IAM ユーザーのセッションの長さ）で、過ぎたら開発者がログインし直す。`~/.aws` はコミットしない。

## 失敗時の動作

次の表は、認証で止まる条件ごとの動作と、開発者がすることを示す。どれもアプリの利用者には影響しない。

| 失敗の条件 | 検知の方法 | 動作 | 開発者がすること |
|---|---|---|---|
| `aws login` の認証情報が期限切れ | 道具のコンテナの `aws` や `terraform` が認証エラーで止まる | 何も作らない | 道具のコンテナで `aws login --remote` を打ち、ログインし直す |
| Terraform が `aws login` の認証情報を読めない | `terraform plan` が `No valid credential sources found` で止まる | 何も作らない | 同じコンテナで `eval "$(aws configure export-credentials --format env)"` を打ち、期限つきの認証情報を環境変数に入れてから `terraform` を打つ |

Terraform が `aws login` の認証情報を読めるバージョンは、[Terraform の state の置き場所の「`aws login` の認証情報を読めるバージョン」](terraform-state-bucket.md#aws-login-の認証情報を読めるバージョン)にある。

## 確認の方法

開発者が道具のコンテナで `aws sts get-caller-identity` を打つと、`user/Administrator` で終わる ARN（AWS のリソースを一意に指す名前）が返る。

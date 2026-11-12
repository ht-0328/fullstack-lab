# GitHub Actions 用の OIDC プロバイダー

GitHub Actions（以下 Actions）は、長期のアクセスキー（期限の無い認証情報）を持たず、OIDC で AWS に認証する。OIDC は、ここでは GitHub が発行するトークンで AWS の期限つきの認証情報を得る仕組みである（[用語](../../architecture/README.md#用語)）。OIDC プロバイダーは、AWS が GitHub の ID トークンの署名を信用するための登録である。この文書は、その登録の中身を記す。

このフォルダの全体と、使う語の意味は [インフラの全体像](README.md) にある。

## 登録の中身

次の表は、OIDC プロバイダーの設定を示す。

| 項目 | 内容 |
|---|---|
| 発行元 | `token.actions.githubusercontent.com` |
| オーディエンス（トークンの宛先。JWT の `aud`） | `sts.amazonaws.com` |
| 作る場所 | Terraform（AWS の構成をコードで書いて作る道具）の `infra/shared`（[Terraform の state の置き場所](terraform-state-bucket.md)） |

OIDC プロバイダーは AWS アカウントに 1 つ作り、[push 用の IAM ロール](ecr-push-role.md)が共通で使う。IAM ロールは、AWS を操作する権限をまとめたものである（[用語](../../architecture/README.md#用語)）。どのリポジトリのどのブランチのジョブに切り替えを許すかは、OIDC プロバイダーではなく、ロールの信頼ポリシー（誰がロールに切り替えてよいかを決めるポリシー）で絞る。

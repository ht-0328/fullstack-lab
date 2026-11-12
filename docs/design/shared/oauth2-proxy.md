# 前段（oauth2-proxy）

この文書は、ローカル環境の前段（アプリより手前で認証とセッションを担う層。[用語](../../architecture/README.md#用語)）である oauth2-proxy の作りを記す。oauth2-proxy は、OpenID Connect のログインを代行するプロキシで、AWS では ALB（AWS のロードバランサー）の認証アクションが担う役割を、ローカルで代わりに担う。設定は、集約リポジトリの `compose.yaml` の環境変数にある。ログインの流れの図は [architecture/ の「ログインの流れ」](../../architecture/README.md#ログインの流れ) にある。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## 担うこと

次の一覧は、oauth2-proxy が担うことを示す。IdP は、ログインを受け付けてトークンを発行するサービスである（[用語](../../architecture/README.md#用語)）。oauth2-proxy は、認可を行わない。

- 未ログインのブラウザを、IdP のログイン画面へ移す（`/oauth2/start`）
- IdP から戻ったブラウザの認可コードを、トークンと交換する（`/oauth2/callback`）
- トークンを暗号化した Cookie に入れて、ブラウザへ渡す。トークンは DB に保存しない
- 入口からの問い合わせに、セッションが有効かどうかと、アクセストークンを返す（`/oauth2/auth`。入口の側は [入口（Nginx）の認証の確認と転送するヘッダー](nginx-auth-headers.md)）
- アクセストークンを更新する
- ログアウトで、Cookie を消し、IdP のセッションも終わらせる（`/oauth2/sign_out`）

## ホストごとのインスタンス

oauth2-proxy は、ホストごとに 1 つ動かす。一般利用者用と社員用で、使う IdP が違うためである。次の表は、2 つのインスタンスの違いを示す。

| 項目 | `oauth2-proxy-customer` | `oauth2-proxy-staff` |
|---|---|---|
| ホスト | `localhost` | `admin.localhost` |
| IdP | Keycloak の realm `customer` | Keycloak の realm `staff`（Okta の代わり） |
| クライアントの ID | `fullstack-lab-customer` | `fullstack-lab-staff` |
| Cookie の名前 | `_fsl_customer` | `_fsl_staff` |

Cookie とインスタンスがホストごとに分かれているので、一般利用者のセッションは社員のホストでは使えない。社員のホストは一般利用者の Cookie を認識せず、401 を返す。

## 共通の設定

次の表は、2 つのインスタンスに共通の設定を示す。

| 項目 | 値 | 理由 |
|---|---|---|
| ログインのフロー | 認可コードフローに PKCE（`S256`）を加える | 認可コードの横取りに備える |
| 要求するスコープ | `openid email profile` | — |
| Cookie の期限 | 8 時間 | — |
| Cookie の更新 | 4 分ごと | アクセストークンの期限の 5 分が切れる前に更新する。oauth2-proxy はトークンを更新し、新しい Cookie を入口経由でブラウザへ返す |
| Cookie の `SameSite` | `lax` | 別サイトからの送信に Cookie を付けさせない |
| Cookie の `Secure` | 付けない | ローカルは HTTP のため。AWS では ALB が HTTPS で Cookie を発行する |
| 入口へ返すヘッダー | 利用者の ID とアクセストークン | 入口が後段へ渡すため |

クライアントシークレットと、Cookie を暗号化するキーは、`.env` から環境変数で渡す。

## IdP の URL

oauth2-proxy は、IdP の URL を自動では取得せず、1 つずつ設定する。同じ Keycloak を、ブラウザとコンテナが別の URL で呼ぶためで、2 つの URL の値と理由は [Keycloak のコンテナ](keycloak-container.md) の「2 つの URL」の節にある。次の表は、oauth2-proxy の設定ごとに、どちらの URL を使うかを示す。

| 設定 | 使う URL |
|---|---|
| 発行元（トークンの `iss` の確認）とログイン画面 | ブラウザから見た URL |
| トークンの交換、公開鍵の取得、ログアウト | コンテナから見た URL |

## 失敗時の動作

次の表は、失敗の条件と、そのときの動作を示す。

| 失敗の条件 | 動作 | 利用者への影響 |
|---|---|---|
| IdP が止まっている | ログイン画面へ移せない。ログイン済みのセッションは、トークンの更新に失敗した時点で無効になる | 復旧までログインできない |

## 確認の方法

oauth2-proxy の動きは、[スモークテスト](smoke-test.md) の「ログイン」「ログアウト」のまとまりで確かめる。

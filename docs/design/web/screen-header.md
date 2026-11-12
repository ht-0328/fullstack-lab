# 共通のヘッダー（`app.vue`）

この文書は、どの画面にも出る共通のヘッダーを記す。ヘッダーは `web/frontend/app/app.vue` にあり、アプリの名前、ログイン中の利用者、パスワード変更とログアウトとログインのリンクを出す。画面の見本は [画面の一覧と遷移](screens/index.html) から開ける各画面の上の帯である。

このフォルダの全体と、使う語の意味は [BFF と画面の全体像](README.md) にある。

## 表示

ヘッダーは、`useMe`（[画面から BFF を呼ぶ共通部品](nuxt-bff-client.md)）で取ったログイン中の利用者で表示を決める。次の表は、表示するものと条件を示す。

| 表示するもの | 条件と中身 |
|---|---|
| アプリの名前 `fullstack-lab` と印 | 一覧（`/`）へのリンク。印は、利用者の種別が社員（`STAFF`）なら「管理画面」、それ以外は「マイページ」 |
| 利用者の名前 | ログイン中は `name`。ログインしていなければ「未認証」 |
| ロール | ログイン中で、表示するロールが 1 つ以上あるときだけ、名前の後ろに括弧で出す |
| 「パスワード変更」のリンク | `capabilities.canChangePassword` が true のときだけ出す。移動先は `/me/password` |
| 「ログアウト」のリンク | ログイン中に出す。移動先は `/oauth2/sign_out?rd=/` |
| 「ログイン」のリンク | ログインしていないときに出す。移動先は `/oauth2/start?rd=/` |

ロールのうち、Keycloak（一般利用者の IdP。[用語](../../architecture/README.md#用語)）が自動で付けるものは表示しない。対象は `offline_access`、`uma_authorization`、`default-roles-` で始まるロールである。

「パスワード変更」のリンクは表示を変えるだけで、操作を止めるのは BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）である（[認可 API への問い合わせ](authz-decision-call.md)）。

## ログインとログアウトの移動先

`/oauth2/start` と `/oauth2/sign_out` は、前段（ローカルは oauth2-proxy、AWS では ALB の認証アクション。[用語](../../architecture/README.md#用語)）のパスである。ログアウトは、前段のセッションを消し、IdP（ログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）の側のセッションも終わらせる。ログインしていない状態でヘッダーが出るのは、未認証で開ける [会員登録の画面](screen-signup.md) だけである。

## テスト

次の表は、ヘッダーについて確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストである。

| 層 | 場所 | 確かめること |
|---|---|---|
| Playwright | `web/e2e/tests/auth.spec.ts` | ログインすると利用者の名前と「マイページ」の印が出ること。「ログアウト」を押すと IdP のセッションも終わり、ログイン画面に戻ること |
| Playwright | `web/e2e/tests/signup.spec.ts` | 社員には「パスワード変更」のリンクが出ないこと |

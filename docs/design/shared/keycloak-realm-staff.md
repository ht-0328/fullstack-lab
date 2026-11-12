# Keycloak の realm `staff` の定義

この文書は、社員のログインに使う Keycloak（IdP のソフトウェア。IdP はログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）の realm `staff` の定義を記す。realm は、Keycloak の中で、Keycloak のユーザーとクライアントをまとめる区画である。realm `staff` は、ローカルで動かせない Okta（社員のログインに使う IdP の製品）の代わりで、社員のロールを IdP のグループの名前で受け取るという仮定（[仮定 5](../../architecture/README.md#仮定)）に合わせて、グループの名前をクレーム（JWT に含まれる項目）で出す。定義は、集約リポジトリの `keycloak/import/staff-realm.json` にある。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## realm 全体の設定

次の表は、realm 全体の設定を示す。

| 設定 | 値 | 意味 |
|---|---|---|
| `registrationAllowed` | `false` | Keycloak のログイン画面からは登録させない |
| `accessTokenLifespan` | `300` | アクセストークンの期限は 300 秒 |
| `sslRequired` | `none` | HTTP での接続を許す |
| グループ | `task-viewer`、`task-admin` | 社員のロールの名前。認可 API の設定のロールの名前と同じにする（[認可 API の設定](../authz/settings.md)） |

## クライアント

realm に定義したクライアントは `fullstack-lab-staff` の 1 つで、クライアントシークレットを持つ。次の表は、クライアントの設定を示す。

| 項目 | 内容 |
|---|---|
| 使う相手 | 社員用の前段 `oauth2-proxy-staff`（[前段（oauth2-proxy）](oauth2-proxy.md)） |
| 有効にしたフロー | 認可コードフロー（PKCE は S256）だけ。Direct Access Grants（ユーザー名とパスワードを直接送ってトークンを得るフロー）は無効 |
| ログイン後の戻り先 | `${STAFF_APP_URL}/oauth2/callback` |
| ログアウト後の戻り先 | `${STAFF_APP_URL}/*` |

次の表は、クライアントがアクセストークンに入れるクレームを示す。

| クレーム | 中身 | 使う相手 |
|---|---|---|
| `aud` | `fullstack-lab-staff` | BFF が宛先として確かめる（[JWT の検証](../web/jwt-verification.md)） |
| `groups` | Keycloak のユーザーが入っているグループの名前の配列。パスの `/` は付けない | BFF がロールとして読む（[CurrentUser](../web/current-user.md)）。Okta がグループをこの名前のクレームで出すという仮定に合わせている |

## テスト用の Keycloak のユーザー

次の表は、realm に居るテスト用の Keycloak のユーザーを示す。

| ユーザー名 | グループ |
|---|---|
| `carol` | `task-viewer` |
| `dave` | `task-admin` |

## 環境変数

定義のファイルは、環境ごとに変わる値と秘密の値を持たず、`${名前}` の形で書く。次の表は、Keycloak が取り込むときに置き換える環境変数を示す。

| 環境変数 | 置き換える先 |
|---|---|
| `STAFF_APP_URL` | `fullstack-lab-staff` の、ログイン後とログアウト後の戻り先の URL |
| `STAFF_CLIENT_SECRET` | `fullstack-lab-staff` のクライアントシークレット |
| `LOCAL_TEST_USER_PASSWORD` | テスト用の Keycloak のユーザーのパスワード |

## 確認の方法

`groups` クレームからロールが得られることは、[スモークテスト](smoke-test.md) の「ログイン」のまとまりで確かめる。

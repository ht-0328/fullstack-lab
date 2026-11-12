# Keycloak の realm `customer` の定義

この文書は、認証 API（[全体像](README.md)）が使う Keycloak の realm `customer` の定義を記す。Keycloak は、一般利用者のログインを受け付けてトークンを発行するサービスである（[用語](../../architecture/README.md#用語)）。realm は、Keycloak の中で、Keycloak に登録されたアカウント（以下、Keycloak のユーザー）とクライアントをまとめる区画である。realm `customer` は、一般利用者の Keycloak のユーザーとクライアントをまとめる。

定義は `auth/keycloak/import/customer-realm.json` にある。realm `customer` の定義を `auth` リポジトリに置くのは、学習用に置いた仮定である（[仮定 14](../../architecture/README.md#仮定)）。Keycloak は、起動時にこのファイルを取り込む。

## realm 全体の設定

次の表は、realm 全体の設定を示す。

| 設定 | 値 | 意味 |
|---|---|---|
| `registrationAllowed` | `false` | Keycloak のログイン画面からは登録させない。登録は認証 API だけが行う |
| `accessTokenLifespan` | `300` | アクセストークンの期限は 300 秒 |
| `sslRequired` | `none` | HTTP での接続を許す |
| realm ロール | `customer` | 一般利用者を示すロール。認証 API が登録のときに付ける |

## クライアント

次の表は、realm に定義したクライアント（Keycloak にトークンを求めるアプリの登録）と、その役割を示す。どちらもクライアントシークレットを持つクライアントである。表の Admin API は、Keycloak のユーザーの作成や更新を行う管理用の API である。

| クライアント | 役割 | 有効にしたフロー |
|---|---|---|
| `fullstack-lab-customer` | 一般利用者のログインに使う。認証 API は使わない。発行するアクセストークンの `aud`（トークンの宛先）に `fullstack-lab-customer` を入れる | 認可コードフロー（ブラウザを Keycloak のログイン画面に送り、戻ってきたコードをトークンに換えるフロー）だけ。PKCE（コードを横取りされても使えなくする仕組み）は S256 を使う。Direct Access Grants（ユーザー名とパスワードを直接送ってトークンを得るフロー）は無効 |
| `auth-api` | 認証 API だけが使う。Admin API 用のトークンの取得と、現在のパスワードの確認に使う | サービスアカウント（Keycloak のユーザーのログインを介さず、クライアント自身の権限でトークンを得る仕組み）と Direct Access Grants。認可コードフローは無効 |

`auth-api` の使い方は、[Admin API 用のトークン](keycloak-admin-token.md) と、[パスワードの変更](password-change.md) の「現在のパスワードの確認」の節にある。

## `auth-api` のサービスアカウントのロール

次の表は、`auth-api` のサービスアカウントに付けたロールを示す。どれも `realm-management`（realm の管理権限のロールをまとめた、Keycloak の組み込みのクライアント）のロールである。

| ロール | 認証 API が使う場面 |
|---|---|
| `manage-users` | Keycloak のユーザーの作成、削除、ロールの付与、パスワードの再設定 |
| `view-users` | Keycloak のユーザーの参照 |
| `view-realm` | realm ロール `customer` の定義の取得 |

## テスト用の Keycloak のユーザー

realm には、テスト用の Keycloak のユーザー `alice` と `bob` が居て、どちらも realm ロール `customer` を持つ。

## 環境変数で置き換える値

定義のファイルは、環境ごとに変わる値と秘密の値を持たず、`${名前}` の形で書く。Keycloak は、取り込むときに同じ名前の環境変数の値に置き換える。次の表は、その環境変数を示す。

| 環境変数 | 置き換える先 |
|---|---|
| `CUSTOMER_APP_URL` | `fullstack-lab-customer` の、ログイン後とログアウト後の戻り先の URL |
| `CUSTOMER_CLIENT_SECRET` | `fullstack-lab-customer` のクライアントシークレット |
| `AUTH_API_CLIENT_SECRET` | `auth-api` のクライアントシークレット。認証 API に渡す同名の環境変数と同じ値にする |
| `LOCAL_TEST_USER_PASSWORD` | テスト用の Keycloak のユーザーのパスワード |

認証 API の側の環境変数は [Keycloak への接続の設定](keycloak-connection.md) にある。

## 保持する個人情報

一般利用者のメールアドレス、姓、名、パスワードを保持するのは、この realm だけである。アプリの DB（タスクの `tasks` 表）には、これらを保存しない。

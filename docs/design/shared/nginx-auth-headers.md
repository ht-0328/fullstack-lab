# 入口（Nginx）の認証の確認と転送するヘッダー

この文書は、ローカル環境の入口（すべてのリクエストを最初に受けて振り分ける Nginx。[用語](../../architecture/README.md#用語)）が、認証をどう確かめ、どのヘッダーを後段へ渡すかを記す。Nginx は、AWS の ALB（AWS のロードバランサー）の認証アクションと同じ名前のヘッダーで、トークンを後段へ渡す（[仮定 3](../../architecture/README.md#仮定)）。BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）の側の扱いは [呼び出し元と受け取るヘッダー](../web/callers-and-headers.md) にある。

流れは [全体像の「認証済みのリクエストが後段に届くまで」](README.md#認証済みのリクエストが後段に届くまで) の図にある。後段は、Nuxt、BFF、Swagger UI のどれかである。このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## 認証の確認

Nginx は、認証が要るパスで、`auth_request`（リクエストごとに別のサービスへ認証の確認を問い合わせる Nginx の機能）を使う。問い合わせ先は、前段（アプリより手前で認証とセッションを担う oauth2-proxy。[用語](../../architecture/README.md#用語)）の `/oauth2/auth` である。

- 前段が 202 とともに返す値のうち、Nginx が後段へ渡すものは「認証済みのリクエストで渡すヘッダー」の節にある
- 401 のときに Nginx が返す応答はパスごとに違い、[入口（Nginx）のホストとパスの振り分け](nginx-routing.md) の「パス」の節にある
- `/oauth2/auth` は Nginx の内部からだけ呼べ、ブラウザからは呼べない

## 認証済みのリクエストで渡すヘッダー

次の表は、Nginx が認証済みのリクエストに付けて後段へ渡すヘッダーを示す。設定は `nginx/snippets/authenticated-proxy.conf` にある。IdP はログインを受け付けてトークンを発行するサービスで、JWT は IdP が署名して発行するトークンである（[用語](../../architecture/README.md#用語)）。

| ヘッダー | 中身 |
|---|---|
| `X-Amzn-Oidc-Accesstoken` | IdP が発行したアクセストークン（JWT）。前段の応答ヘッダー `X-Auth-Request-Access-Token` の値 |
| `X-Amzn-Oidc-Identity` | 利用者の ID。前段の応答ヘッダー `X-Auth-Request-User` の値 |
| `X-Amzn-Oidc-Data` | 空にするので、後段へは送られない（ブラウザなどの呼び出し側が付けてきた値も届かない）。ALB が署名する JWT は、ローカルでは再現しない |
| `X-Request-Id` | Nginx がリクエストごとに振る ID。応答のヘッダーにも同じ値を付ける |
| `Host`、`X-Forwarded-For`、`X-Forwarded-Proto` | 元のホスト、呼び出し側の IP アドレス、元のスキーム |

ブラウザなどの呼び出し側が `X-Amzn-Oidc-` で始まる同じ名前のヘッダーを送ってきても、Nginx はこの表の値で上書きする。偽のトークンを後段へ届かせないためである。入口を通らずに BFF へ届いたトークンは、BFF が署名を検証して拒否する（[JWT の検証](../web/jwt-verification.md)）。

前段がトークンを更新して Cookie を発行し直したとき、Nginx はその `Set-Cookie` を応答に付けてブラウザへ返す。

## 公開パスで渡すヘッダー

公開パスのリクエストは認証していないので、Nginx は `X-Amzn-Oidc-Identity`、`X-Amzn-Oidc-Accesstoken`、`X-Amzn-Oidc-Data` の 3 つを空にして転送する。Nginx は値が空のヘッダーを後段へ送らないので、この 3 つは後段に届かず、ブラウザなどの呼び出し側が付けてきた値も届かない。`X-Request-Id` と `Host`、`X-Forwarded-For`、`X-Forwarded-Proto` は、認証済みのリクエストと同じに付ける。設定は `nginx/snippets/public-proxy.conf` にある。

## バッファの大きさ

Nginx は、応答ヘッダーとリクエストヘッダーのバッファを 16k に広げている。認証のあとの `Set-Cookie` と、Cookie を付けたリクエストのヘッダーが大きくなるためである。

## 確認の方法

偽のトークンのヘッダーが後段に届かないことは、[スモークテスト](smoke-test.md) の「入口と未認証アクセス」「ログイン」「会員登録とパスワード変更」のまとまりで確かめる。

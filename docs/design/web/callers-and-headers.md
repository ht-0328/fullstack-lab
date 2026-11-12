# 呼び出し元と受け取るヘッダー

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）の呼び出し元と、BFF が受け取るヘッダーを記す。記すのは、呼び出し元、呼び出し元が渡すヘッダー、BFF が持たないものの 3 つである。BFF の全体は [BFF と画面の全体像](README.md) にある。

## 呼び出し元

BFF を呼ぶのは、ブラウザと、Nuxt（画面のフレームワーク）のサーバーの 2 つである。ブラウザのリクエストは、入口（すべてのリクエストを最初に受けて振り分けるもの。ローカルは Nginx、AWS では ALB。[用語](../../architecture/README.md#用語)）が `/bff/` を BFF へ転送する。Nuxt のサーバーは、SSR（サーバー側で HTML を作る描画）のときに、入口を通さず BFF を直接呼ぶ。

## 受け取るヘッダー

次の表は、呼び出し元が BFF に渡すヘッダーと、BFF での用途を示す。Nuxt のサーバーは、入口から受け取ったこれらのヘッダーを、そのまま BFF に渡す。

| ヘッダー | 中身 | BFF での用途 |
|---|---|---|
| `x-amzn-oidc-accesstoken` | IdP（ログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）が発行したアクセストークン。入口が付ける | 検証して、利用者を特定する（[JWT の検証](jwt-verification.md)） |
| `x-amzn-oidc-identity` | 入口が付ける、ログインした利用者の ID（[入口（Nginx）の認証の確認と転送するヘッダー](../shared/nginx-auth-headers.md)） | BFF は使わない。利用者はアクセストークンから特定する |
| `X-Request-Id` | 入口が付けたリクエストの ID | ログの各行に `requestId` として出し、呼び出す先にも同じ値を渡す（[API、認可 API、認証 API の呼び出し](upstream-clients.md)）。ヘッダーが無ければ `-` とする |

## BFF が持たないもの

BFF は、セッションも Cookie も持たない。ログイン画面への移動とセッションの Cookie は、前段（ローカルは oauth2-proxy、AWS では ALB の認証アクション。[用語](../../architecture/README.md#用語)）が担う。BFF は JSON だけを受け付け、CSRF トークン（別サイトからの勝手な送信を防ぐための値）は使わない。

## テスト

次の表は、呼び出し元からの経路について確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストで、集約リポジトリ（このリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）で全体を起動して実行する。

| 層 | 場所 | 確かめること |
|---|---|---|
| Playwright | `web/e2e/tests/` | ログインとログアウト（確かめる中身は [共通のヘッダーの「テスト」](screen-header.md#テスト)） |

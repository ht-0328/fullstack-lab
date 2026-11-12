# 画面から BFF を呼ぶ共通部品（`useBff`、`useMe`）

この文書は、画面（Nuxt。画面を作るフレームワーク）が BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）を呼ぶときに使う共通部品を記す。部品は `web/frontend/app/composables/useBff.ts` にあり、どの画面もこの部品を通して BFF を呼ぶ。画面ごとの作りは [BFF と画面の全体像](README.md) の表にある文書に書く。

## BFF を呼ぶ 2 つの経路

画面が BFF を呼ぶ経路は、初回の表示で Nuxt のサーバーが呼ぶ経路と、表示のあとにブラウザが呼ぶ経路の 2 つである。Nuxt のサーバーが呼ぶ経路の流れは [全体像の「共通の流れ」](README.md#共通の流れ) の図にある。経路ごとの呼び出す先とヘッダーは「呼び出す先と渡すヘッダー」の節に、401 のときの動きは「401 の扱い」の節にある。

## 型の生成

画面は、BFF の契約（リポジトリの間のやり取りを決める OpenAPI の仕様。[用語](../../architecture/README.md#用語)）`web/openapi/bff.yaml` から、型だけを生成して使う（[仮定 11](../../architecture/README.md#仮定)）。生成物は `web/frontend/app/types/bff.d.ts` で、生成のコマンドと生成器は [契約からのコード生成](../shared/code-generation.md) にある。HTTP の呼び出しは `openapi-fetch`（生成した型を使って fetch を呼ぶライブラリ）に任せる。型だけを生成する方針と理由は [ADR-0001 画面（Nuxt）は OpenAPI から型だけを生成し、HTTP の層は生成しない](../../adr/ADR-0001-nuxt-generates-types-only.md) にある。

## 呼び出す先と渡すヘッダー

`useBff` は、動いている場所で呼び出す先を変える。次の表は、場所ごとの呼び出す先と、渡すヘッダーを示す。SSR は、Nuxt のサーバーが HTML を作る描画である。

| 動いている場所 | 呼び出す先 | 渡すヘッダー |
|---|---|---|
| Nuxt のサーバー（SSR） | 設定 `bffInternalBase` の URL。環境変数 `NUXT_BFF_INTERNAL_BASE` で渡し、既定は `http://localhost:8081` | 元のリクエストの `x-amzn-oidc-accesstoken`、`x-amzn-oidc-identity`、`X-Request-Id` を引き継ぐ |
| ブラウザ | 設定 `bffPublicBase` の URL。既定は空で、画面と同じオリジンの `/bff/*` になる | 画面は付けない。入口（すべてのリクエストを最初に受けて振り分けるもの。[用語](../../architecture/README.md#用語)）が付ける |

Nuxt のサーバーがヘッダーを引き継ぐのは、SSR の呼び出しが入口を通らないためである。BFF がこれらのヘッダーをどう使うかは [呼び出し元と受け取るヘッダー](callers-and-headers.md) にある。

## 401 の扱い

ブラウザで BFF が 401 を返したら、`useBff` は `/oauth2/start?rd=<今のパス>` へ移動し、ログインからやり直させる。Nuxt のサーバーでは移動しない。

## 失敗の扱い（`unwrap`）

`unwrap` は、BFF の応答を「成功なら中身を返し、失敗ならエラーを投げる」形に変える。投げるエラーには、ステータスコード、Problem Details の `title`、応答の本文を載せる。SSR でデータを取る画面は、このステータスコードで表示を分ける。BFF のエラーの形は [エラー応答](error-responses.md) にある。

## ログイン中の利用者（`useMe`）

`useMe` は、`GET /bff/me` を呼んでログイン中の利用者を返す。共通のヘッダーと各画面は、同じキー `me`（Nuxt が同じデータの取得を 1 回にまとめるための名前）で呼ぶので、取得は 1 回にまとまる。応答の中身は [利用者情報（`GET /bff/me`）](me.md) にある。

BFF が 401 を返したときは、`useMe` はエラーにせず「ログインしていない」（`null`）として返す。会員登録の画面を、ログインしていないまま描画するためである。

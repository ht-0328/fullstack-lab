# パスワード変更（`PUT /bff/me/password`）

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）のエンドポイント `PUT /bff/me/password` の処理を記す。このエンドポイントは、ログイン中の利用者のパスワードを変える。パスワード変更は、一般利用者が自分のアカウントに対してだけ行える。

流れは [全体像の「パスワード変更」](README.md#パスワード変更) の図にある。

## 処理と応答

応答は 204 である。入力が不正なら 400、拒否されたとき、または現在のパスワードが違うときは 403 を返す。次の箇条書きは、図の各段の理由と条件を示す。

- `account:change-password` の問い合わせでは、自分の ID を対象の所有者にする（[認可 API への問い合わせ](authz-decision-call.md)）。拒否されたら、BFF は 403 を返し、認証 API は呼ばない。社員は、アカウントを IdP（ログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）の側で管理するので、ここで拒否される
- 認証 API の `PUT /auth/v1/customers/{id}/password` の `{id}` には、`CurrentUser`（BFF の中で使う利用者情報。[CurrentUser](current-user.md)）の `id` を使う。この値は、JWT（IdP が署名して発行するトークン。[用語](../../architecture/README.md#用語)）の `sub` である。リクエストには利用者の ID の項目が無いので、他人のアカウントは指定できない
- 現在のパスワードが違うときの 403 は、認証 API が返したものを、BFF がそのまま返す

入力の検証の方法、エラーの形、ここに無いステータスコードは [エラー応答](error-responses.md) にある。

## テスト

次の表は、このエンドポイントについて確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストで、集約リポジトリ（このリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）で全体を起動して実行する。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `web/bff/src/test/` の `AccountServiceTest` | 社員のパスワード変更は認証 API を呼ばずに拒否すること。一般利用者のパスワード変更は JWT の `sub` を利用者の ID に使うこと |
| Playwright | `web/e2e/tests/` | 変更の操作（確かめる中身は [パスワード変更の画面の「テスト」](screen-password-change.md#テスト)） |

## 関連

次の文書は、BFF が呼ぶ認証 API の側の処理を書いたものである。

- 認証 API のパスワード変更: [認証 API のパスワード変更](../auth/password-change.md)

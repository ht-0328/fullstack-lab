# 利用者情報（`GET /bff/me`）

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）のエンドポイント `GET /bff/me` の処理を記す。このエンドポイントは、ログイン中の利用者の情報と、画面の出し分け用の値 `capabilities` を返す。

流れは [全体像の「利用者情報の取得」](README.md#利用者情報の取得) の図にある。

## 処理と応答

BFF は、`CurrentUser`（BFF の中で使う利用者情報。[CurrentUser](current-user.md)）の値に、`capabilities` を足して返す。BFF は、API と認証 API を呼ばない。応答は 200 と利用者情報である。

## `capabilities` の値

`capabilities` は、画面がボタンや導線を出すかどうかを決めるための値で、操作を止める役目は持たない（[認可 API への問い合わせの「画面の出し分け用の値の問い合わせ」](authz-decision-call.md#画面の出し分け用の値の問い合わせ)）。次の表は、値ごとに、認可 API に問い合わせる内容を示す。

| 値 | 問い合わせる内容 |
|---|---|
| `capabilities.canCreateTask` | 自分の ID を対象の所有者として `task:create` を問い合わせた結果 |
| `capabilities.canChangePassword` | 自分の ID を対象の所有者として `account:change-password` を問い合わせた結果 |

BFF は、認可 API に 2 回問い合わせる。認可 API から可否を受け取れないとき、BFF は 503 を返す（[認可 API への問い合わせの「可否を受け取れない場合の扱い」](authz-decision-call.md#可否を受け取れない場合の扱い)）。

## テスト

次の表は、このエンドポイントについて確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストで、集約リポジトリ（このリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）で全体を起動して実行する。

| 層 | 場所 | 確かめること |
|---|---|---|
| Playwright | `web/e2e/tests/` | 利用者の種別とロールごとの出し分け（確かめる中身は [共通のヘッダーの「テスト」](screen-header.md#テスト) と [タスク一覧の画面の「テスト」](screen-task-list.md#テスト)） |

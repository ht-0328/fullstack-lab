# タスクの登録（`POST /bff/tasks`）

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）のエンドポイント `POST /bff/tasks` の処理を記す。このエンドポイントは、タスクを 1 件登録する。登録では、BFF が利用者の ID と名前を API に渡す。

流れは [全体像の「タスクの登録」](README.md#タスクの登録) の図にある。

## 処理と応答

BFF が認可 API に問い合わせる操作は `task:create` である（[認可 API への問い合わせ](authz-decision-call.md)）。応答は 201 と登録したタスクで、入力が不正なら 400、拒否されたら 403 である。

- BFF は、`CurrentUser`（BFF の中で使う利用者情報。[CurrentUser](current-user.md)）の `id` を `X-User-Id`、`name` を `X-User-Name` として API の `POST /api/tasks` に渡す。API はこの 2 つを登録者として保存する
- BFF は、API が返したタスクを一覧用の形にして返す

入力の検証の方法、エラーの形、ここに無いステータスコードは [エラー応答](error-responses.md) にある。

## テスト

次の表は、このエンドポイントについて確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストで、集約リポジトリ（このリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）で全体を起動して実行する。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `web/bff/src/test/` の `TaskViewServiceTest` | 拒否された登録では API を呼ばないこと |
| Playwright | `web/e2e/tests/` | 登録の操作（確かめる中身は [タスク登録の画面の「テスト」](screen-task-new.md#テスト)） |

## 関連

次の文書は、BFF が呼ぶ API の側の処理を書いたものである。

- API の登録: [API のタスクの登録](../api/task-create.md)

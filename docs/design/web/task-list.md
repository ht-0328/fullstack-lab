# タスクの一覧（`GET /bff/tasks`）

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）のエンドポイント `GET /bff/tasks` の処理を記す。このエンドポイントは、タスクの一覧を返す。一覧は、利用者の種別で対象の範囲が変わる。

流れは [全体像の「タスクの一覧」](README.md#タスクの一覧) の図にある。

## 処理と応答

BFF が認可 API に問い合わせる操作は `task:list` である（[認可 API への問い合わせ](authz-decision-call.md)）。応答は 200 と一覧用のタスクの配列で、拒否されたら 403 である。

- 対象の範囲は、API の `GET /api/tasks` の query parameter の `ownerId` で決める。一般利用者には自分の ID を渡して自分が登録したタスクだけを取り、社員には付けずに全件を取る
- BFF は、API が返したタスクから、一覧に使う項目（ID、タイトル、期限日、登録者の名前、完了日時）だけを返す

エラーの形と、ここに無いステータスコードは [エラー応答](error-responses.md) にある。

## テスト

次の表は、このエンドポイントについて確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストで、集約リポジトリ（このリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）で全体を起動して実行する。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `web/bff/src/test/` の `TaskViewServiceTest` | 一般利用者の一覧は自分のタスクに絞り、社員の一覧は絞らないこと |
| Playwright | `web/e2e/tests/` | 一覧の表示（確かめる中身は [タスク一覧の画面の「テスト」](screen-task-list.md#テスト)） |

## 関連

次の文書は、BFF が呼ぶ API の側の処理を書いたものである。

- API の一覧: [API のタスクの一覧](../api/task-list.md)

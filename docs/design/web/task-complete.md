# タスクの完了（`POST /bff/tasks/{id}/complete`）

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）のエンドポイント `POST /bff/tasks/{id}/complete` の処理を記す。このエンドポイントは、タスクを完了にする。応答は 200 と完了後の詳細で、タスクが無ければ 404、拒否されたら 403 である。

流れは [全体像の「タスクの完了」](README.md#タスクの完了) の図にある。

## 処理と応答

次の箇条書きは、図の各段について、理由と、応答を決める条件を示す。

- タスクを認可より先に API の `GET /api/tasks/{id}` で取るのは、登録者の ID を知るためである
- `task:complete` の問い合わせでは、タスクの登録者の ID を対象の所有者にする（[認可 API への問い合わせ](authz-decision-call.md)）。拒否されたら、BFF は 403 を返し、API の完了は呼ばない。詳細と違って 404 にはしない
- 完了は API の `POST /api/tasks/{id}/completion` で行う。既に完了しているタスクでは、API が何も変えずに今のタスクを返すので、BFF は完了済みかどうかを区別しない（冪等。[用語](../../architecture/README.md#用語)）
- 応答は、API が返したタスクを詳細と同じ形にしたものである。補足情報も詳細と同じ決まりで足す（[タスクの詳細の「補足情報の縮退」](task-detail.md#補足情報の縮退)）。完了日時が入っているので、`canComplete` は false になる

エラーの形と、ここに無いステータスコードは [エラー応答](error-responses.md) にある。

## テスト

次の表は、このエンドポイントについて確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストで、集約リポジトリ（このリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）で全体を起動して実行する。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `web/bff/src/test/` の `TaskViewServiceTest` | 拒否された完了では API を呼ばないこと。無いタスクの完了は 404 になること |
| Playwright | `web/e2e/tests/` | 完了の操作（確かめる中身は [タスク詳細の画面の「テスト」](screen-task-detail.md#テスト)） |

## 関連

次の文書は、BFF が呼ぶ API の側の処理を書いたものである。

- API の完了: [API のタスクの完了](../api/task-completion.md)

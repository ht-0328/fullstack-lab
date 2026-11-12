# タスクの詳細（`GET /bff/tasks/{id}`）

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）のエンドポイント `GET /bff/tasks/{id}` の処理を記す。このエンドポイントは、タスク、期限日の補足情報、`canComplete` の 3 つをまとめて返す。応答は 200 と詳細で、タスクが無い、または閲覧を拒否されたら 404 である。

流れは [全体像の「タスクの詳細」](README.md#タスクの詳細) の図にある。

## 処理と応答

次の箇条書きは、図の各段について、その順にする理由と、応答を決める条件を示す。

- タスクを認可より先に取るのは、登録者の ID が分からないと、認可 API に問い合わせられないためである。タスクは API の `GET /api/tasks/{id}` で取る
- `task:read` の問い合わせでは、タスクの登録者の ID を対象の所有者にする（[認可 API への問い合わせ](authz-decision-call.md)）。拒否されたら、BFF は 403 ではなく 404 を返す。タスクが無いときと同じ応答にして、その ID のタスクがあることを知らせないためである
- 補足情報は、「補足情報の縮退」の節の決まりで足す
- `canComplete` は、「`canComplete` の値」の節の決まりで足す

エラーの形と、ここに無いステータスコードは [エラー応答](error-responses.md) にある。

## 補足情報の縮退

補足情報は、期限日が営業日かどうかと祝日の名前で、API が外部サービスから取る。BFF は、補足情報が取れなくても詳細をエラーにせず、補足情報だけを諦めて返す（縮退。[用語](../../architecture/README.md#用語)）。次の表は、`dueDateInfoStatus` の値と、その条件を示す。

| `dueDateInfoStatus` | 条件 | `dueDateInfo` |
|---|---|---|
| `NO_DUE_DATE` | タスクに期限日が無い。BFF は API の `due-date-info` を呼ばない | 空 |
| `AVAILABLE` | API の `GET /api/tasks/{id}/due-date-info` が 200 を返した | API が返した値 |
| `UNAVAILABLE` | `due-date-info` の呼び出しが失敗した。API の 502、ほかの 4xx と 5xx、タイムアウト、接続の失敗を区別しない | 空 |

`UNAVAILABLE` のとき、BFF は `WARN` のログにタスクの ID と理由を出す。

### API の 502 の扱い

API は、外部サービスから補足情報を取れないときに 502 を返す。BFF は、この 502 を画面に返さず、`dueDateInfoStatus` を `UNAVAILABLE` にして詳細を 200 で返す。補足情報以外の呼び出し（例: `GET /api/tasks/{id}`）で API が 5xx を返したときは、BFF は 502 を返す。

## `canComplete` の値

`canComplete` は、画面が「完了にする」の操作を出すかどうかを決めるための値で、操作を止める役目は持たない（[認可 API への問い合わせの「画面の出し分け用の値の問い合わせ」](authz-decision-call.md#画面の出し分け用の値の問い合わせ)）。BFF は、この値を `GET /bff/tasks/{id}` と `POST /bff/tasks/{id}/complete` の応答で返す。

- タスクに完了日時が入っていれば、BFF は認可 API に問い合わせずに false にする
- 未完了なら、BFF は、タスクの登録者の ID を対象の所有者として `task:complete` を問い合わせた結果にする

認可 API への問い合わせは、未完了のタスクの詳細で 2 回（`task:read` と `task:complete`）、完了済みのタスクの詳細で 1 回である。認可 API から可否を受け取れないとき、BFF は 503 を返す（[認可 API への問い合わせの「可否を受け取れない場合の扱い」](authz-decision-call.md#可否を受け取れない場合の扱い)）。

## テスト

次の表は、このエンドポイントについて確かめることを示す。Playwright は、ブラウザを操作して画面を確かめるテストで、集約リポジトリ（このリポジトリ fullstack-lab。[用語](../../architecture/README.md#用語)）で全体を起動して実行する。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `web/bff/src/test/` の `TaskViewServiceTest` | 他人のタスクの詳細は 404 になること |
| 単体 | `web/bff/src/test/` の `TaskViewServiceTest` | 詳細に補足情報を足すこと、取れないときは `UNAVAILABLE` にすること、期限日が無ければ取りに行かないこと。`canComplete` が認可の結果に従い、完了済みでは問い合わせずに false になること |
| Playwright | `web/e2e/tests/` | 詳細の表示、補足情報の縮退、利用者の種別とロールごとの出し分け（確かめる中身は [タスク詳細の画面の「テスト」](screen-task-detail.md#テスト)） |

## 関連

次の文書は、BFF が呼ぶ API の側の処理を書いたものである。

- API のタスクの取得: [API のタスクの取得](../api/task-get.md)
- API の補足情報: [API の期限日の補足情報](../api/due-date-info.md)

# タスクの完了（`POST /api/tasks/{id}/completion`）

この文書は、`api` リポジトリが作る API のうち、タスクを完了にする `POST /api/tasks/{id}/completion` を記す。API はタスクを保存して返すサービスで、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [api.yaml](../../../api/openapi/api.yaml) にあるので、この文書には書き写さない。

流れは [全体像の「タスクの完了」](README.md#タスクの完了) の図にある。

## 処理と応答

次の表は、`POST /api/tasks/{id}/completion` の処理と応答を示す。エラーの形は [エラー応答](error-responses.md) にある。

| エンドポイント | 処理 | 応答 |
|---|---|---|
| `POST /api/tasks/{id}/completion` | 未完了なら完了日時に今の時刻を入れる。既に完了していれば何も変えない | 200 とタスク。無ければ 404 |

## 完了の処理

完了は、何回呼んでも結果が同じになる（冪等。[用語](../../architecture/README.md#用語)）。二重クリックや再送をエラーにしないためである。

- 更新は「ID が一致し、完了日時が空の行」だけを対象にする。同時に 2 回呼ばれても、完了日時が入るのは 1 回だけになる
- 更新した行が無いときに ID でタスクを取り直すのは、既に完了しているタスクと、無いタスクを区別するためである
- 完了日時は、最初に入れた値のまま変えない

完了日時を入れる列は [`tasks` 表](tasks-table.md) の `completed_at` である。

## テスト

次の表は、`api` リポジトリの中で確かめることを示す。Karate は API を HTTP で呼んで確かめるテストで、WireMock は HTTP の応答を定義して返すスタブサーバーである。

| 層 | 場所 | 確かめること |
|---|---|---|
| Karate | `api/karate/features/tasks.feature`（`api/compose.test.yaml` で API、DB、WireMock を起動して実行） | `POST /api/tasks/{id}/completion` の応答と、完了を 2 回呼んでも完了日時が変わらないこと |

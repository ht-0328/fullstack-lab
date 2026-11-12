# タスクの一覧（`GET /api/tasks`）

この文書は、`api` リポジトリが作る API のうち、タスクの一覧を返す `GET /api/tasks` を記す。API はタスクを保存して返すサービスで、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [api.yaml](../../../api/openapi/api.yaml) にあるので、この文書には書き写さない。

このフォルダの全体と、使う語の意味は [API の全体像](README.md) にある。

## 処理と応答

次の表は、`GET /api/tasks` の処理と応答を示す。エラーの形は [エラー応答](error-responses.md) にある。

| エンドポイント | 処理 | 応答 |
|---|---|---|
| `GET /api/tasks` | [`tasks` 表](tasks-table.md) を ID の大きい順（新しい順）に返す。query parameter の `ownerId` があれば、登録者の ID が一致するタスクだけにする | 200 とタスクの配列。0 件なら空の配列 |

## テスト

次の表は、`api` リポジトリの中で確かめることを示す。Karate は API を HTTP で呼んで確かめるテストで、WireMock は HTTP の応答を定義して返すスタブサーバーである。

| 層 | 場所 | 確かめること |
|---|---|---|
| Karate | `api/karate/features/tasks.feature`（`api/compose.test.yaml` で API、DB、WireMock を起動して実行） | `GET /api/tasks` の応答 |

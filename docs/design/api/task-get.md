# タスクの取得（`GET /api/tasks/{id}`）

この文書は、`api` リポジトリが作る API のうち、タスクを 1 件返す `GET /api/tasks/{id}` を記す。API はタスクを保存して返すサービスで、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [api.yaml](../../../api/openapi/api.yaml) にあるので、この文書には書き写さない。

このフォルダの全体と、使う語の意味は [API の全体像](README.md) にある。

## 処理と応答

次の表は、`GET /api/tasks/{id}` の処理と応答を示す。エラーの形は [エラー応答](error-responses.md) にある。

| エンドポイント | 処理 | 応答 |
|---|---|---|
| `GET /api/tasks/{id}` | ID でタスクを 1 件取る | 200 とタスク。無ければ 404 |

## テスト

次の表は、`api` リポジトリの中で確かめることを示す。Karate は API を HTTP で呼んで確かめるテストで、WireMock は HTTP の応答を定義して返すスタブサーバーである。

| 層 | 場所 | 確かめること |
|---|---|---|
| Karate | `api/karate/features/tasks.feature`（`api/compose.test.yaml` で API、DB、WireMock を起動して実行） | `GET /api/tasks/{id}` の応答 |

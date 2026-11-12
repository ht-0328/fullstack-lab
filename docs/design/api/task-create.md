# タスクの登録（`POST /api/tasks`）

この文書は、`api` リポジトリが作る API のうち、タスクを登録する `POST /api/tasks` を記す。API はタスクを保存して返すサービスで、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [api.yaml](../../../api/openapi/api.yaml) にあるので、この文書には書き写さない。

このフォルダの全体と、使う語の意味は [API の全体像](README.md) にある。

## 処理と応答

次の表は、`POST /api/tasks` の処理と応答を示す。ヘッダー `X-User-Id` と `X-User-Name` の中身は [呼び出し元と受け取るヘッダー](callers-and-headers.md) に、エラーの形は [エラー応答](error-responses.md) にある。

| エンドポイント | 処理 | 応答 |
|---|---|---|
| `POST /api/tasks` | 入力を検証し、`X-User-Id` と `X-User-Name` を登録者として [`tasks` 表](tasks-table.md) に 1 行足す | 201 と登録したタスク。`Location` ヘッダーに `/api/tasks/{id}`。入力が不正か、ヘッダー `X-User-Id` か `X-User-Name` が無ければ 400 |

## 入力の検証

登録の入力の決まり（必須かどうか、文字数、日付の形式）は、契約の `POST /api/tasks` のリクエストの定義に書き、契約から生成したコードが検証する。決まりに合わない入力には 400 を返す。

## テスト

次の表は、`api` リポジトリの中で確かめることを示す。Karate は API を HTTP で呼んで確かめるテストで、WireMock は HTTP の応答を定義して返すスタブサーバーである。

| 層 | 場所 | 確かめること |
|---|---|---|
| Karate | `api/karate/features/tasks.feature`（`api/compose.test.yaml` で API、DB、WireMock を起動して実行） | `POST /api/tasks` の応答と、入力の検証 |

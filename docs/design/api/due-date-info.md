# 期限日の補足情報（`GET /api/tasks/{id}/due-date-info`）

この文書は、`api` リポジトリが作る API のうち、タスクの期限日の補足情報を返す `GET /api/tasks/{id}/due-date-info` と、その中で行う外部サービス（日付が営業日か祝日かを返すカレンダー API）の呼び出しを記す。API はタスクを保存して返すサービスで、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [api.yaml](../../../api/openapi/api.yaml) にあるので、この文書には書き写さない。

流れは [全体像の「期限日の補足情報」](README.md#期限日の補足情報) の図にある。

## 処理と応答

次の表は、`GET /api/tasks/{id}/due-date-info` の処理と応答を示す。エラーの形は [エラー応答](error-responses.md) にある。

| エンドポイント | 処理 | 応答 |
|---|---|---|
| `GET /api/tasks/{id}/due-date-info` | タスクの期限日を外部サービスに問い合わせ、営業日かどうかと祝日の名前を返す | 200 と補足情報。タスクが無い、または期限日が無ければ 404。外部サービスから取れなければ 502 |

## 外部サービスの呼び出し

API が外部サービスを呼ぶのは、`GET /api/tasks/{id}/due-date-info` の中だけである（[仮定 9](../../architecture/README.md#仮定)）。

次の表は、API が外部サービスを呼ぶときのリクエスト、応答、設定を示す。値の出所は `api/src/main/resources/application.yml` の `external.calendar` である。

| 項目 | 内容 |
|---|---|
| リクエスト | `GET {base-url}/v1/days/{日付}`。ヘッダー `X-Api-Key` に API キーを付ける |
| 応答 | `date`（日付）、`businessDay`（営業日かどうか）、`holidayName`（祝日の名前。無ければ空） |
| タイムアウト | 接続 2 秒、読み取り 3 秒 |
| 接続先と API キー | 環境変数 `EXTERNAL_CALENDAR_BASE_URL` と `EXTERNAL_CALENDAR_API_KEY` |
| 失敗の扱い | 4xx、5xx、タイムアウト、接続の失敗を区別せず、どれも 502 で返す。API が返す 502 の `detail` は `calendar service unavailable` である。再試行はしない |

外部サービスから取れないときに、補足情報を付けずにタスクの詳細を返すかどうかは、API では決めず、502 を受けた BFF が決める。BFF の扱いは [タスクの詳細（BFF）](../web/task-detail.md) にある。

## ローカルでの代わり

ローカルでは、外部サービスの代わりに WireMock（HTTP の応答を定義して返すスタブサーバー）を使う。応答の定義は `api/wiremock/mappings/` にあり、日付が 2026-11-03 なら祝日の応答を、2099-12-31 なら 500 を返す。

## テスト

次の表は、`api` リポジトリの中で確かめることを示す。Karate は、API を HTTP で呼んで確かめるテストである。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `api/src/test/` の `CalendarClientTest` | 外部サービスの応答の読み取りと、失敗の扱い |
| Karate | `api/karate/features/tasks.feature`（`api/compose.test.yaml` で API、DB、WireMock を起動して実行） | `GET /api/tasks/{id}/due-date-info` の応答と、外部サービスの失敗で 502 になること |

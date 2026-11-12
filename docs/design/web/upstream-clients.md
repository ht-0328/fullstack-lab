# API、認可 API、認証 API の呼び出し

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）が他のサービスを呼ぶ方法を記す。BFF が呼ぶのは、API、認可 API、認証 API の 3 つである。BFF は、それぞれのリポジトリが契約（領域同士の API の取り決め。各領域の `openapi/*.yaml`）から生成して publish（Maven リポジトリに登録すること。[用語](../../architecture/README.md#用語)）したクライアントのライブラリで呼び、相手のソースは参照しない（[仮定 10](../../architecture/README.md#仮定)）。

このフォルダの全体と、使う語の意味は [BFF と画面の全体像](README.md) にある。

成果物として配布する方針と理由は [ADR-0002 領域間のクライアントは成果物（Maven）として配布し、ソースを共有しない](../../adr/ADR-0002-distribute-clients-as-artifacts.md) に、配布の仕組みは [生成クライアントの publish と取得](../shared/client-distribution.md) にある。

## クライアント、接続先、タイムアウト

次の表は、呼び出す先ごとのクライアント、接続先、タイムアウトを示す。クライアントのバージョンは `web/bff/gradle.properties` にあり、相手の契約が変わったらここを上げる。タイムアウトの既定は、`web/bff/src/main/kotlin/com/example/fullstacklab/bff/` の `task/ApiClientConfig.kt`、`authz/AuthzClient.kt`、`account/AccountService.kt` にある。

| 呼び出す先 | クライアントとバージョン | 接続先の環境変数 | タイムアウト |
|---|---|---|---|
| API | `api-client` 1.1.0（`apiClientVersion`） | `API_BASE_URL` | 接続 2 秒、読み取り 5 秒 |
| 認可 API | `authz-client` 1.0.0（`authzClientVersion`） | `AUTHZ_BASE_URL` | 接続 1 秒、読み取り 2 秒 |
| 認証 API | `auth-client` 1.0.0（`authClientVersion`） | `AUTH_API_BASE_URL` | 接続 2 秒、読み取り 5 秒 |

BFF は、どの呼び出しも再試行しない。相手が失敗したときに BFF が返すエラーは [エラー応答](error-responses.md) にある。

## 渡すヘッダー

次の表は、BFF が呼び出す先に渡すヘッダーを示す。BFF は、受け取った JWT（IdP が署名して発行するトークン。[用語](../../architecture/README.md#用語)）を呼び出す先に渡さない。

| ヘッダー | 渡す先 | 中身 |
|---|---|---|
| `X-Request-Id` | API、認可 API、認証 API のすべての呼び出し | BFF が受け取った `X-Request-Id` の値（[呼び出し元と受け取るヘッダー](callers-and-headers.md)）。サービスをまたいで、同じ ID でログを追える |
| `X-User-Id`、`X-User-Name` | API の `POST /api/tasks` だけ | 登録者の ID と名前。中身は [タスクの登録（`POST /bff/tasks`）](task-create.md) にある |

## テスト

BFF の単体テストは、publish されたクライアントをそのまま使い、HTTP の応答だけを `MockRestServiceServer`（Spring のテスト用の部品）で差し替えて、BFF の処理を確かめる。確かめることは、各エンドポイントの文書の「テスト」の節にある。

単体テストは、`web/bff/Dockerfile` の `test` ステージで実行する。このステージは、先に生成コードの検査を通す（[生成コードの検査（`check-generated`）](../shared/check-generated.md)）。

## 関連

次の文書は、呼び出す先の側の処理を書いたものである。

- API のエンドポイントごとの処理: [API の全体像](../api/README.md)
- 認可 API: [認可 API の全体像](../authz/README.md)
- 認証 API: [認証 API の全体像](../auth/README.md)

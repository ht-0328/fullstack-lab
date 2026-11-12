# API の呼び出し元と受け取るヘッダー

この文書は、`api` リポジトリが作る API の呼び出し元と、API が受け取るヘッダーを記す。API はタスクを保存して返すサービスで、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。API の全体像は [API の全体像](README.md) にある。

## 認証と認可

API は、認証も認可も行わない（[仮定 7](../../architecture/README.md#仮定)）。BFF が認証と認可を済ませてから呼ぶ前提で、入口（すべてのリクエストを最初に受けて振り分ける Nginx。[用語](../../architecture/README.md#用語)）は API へ転送せず、`/api/` へのリクエストに 404 を返す。

## 受け取るヘッダー

次の表は、BFF が API に渡すヘッダーと、API での用途を示す。

| ヘッダー | 中身 | API での用途 |
|---|---|---|
| `X-User-Id` | 利用者の ID（JWT の `sub`。JWT は IdP が署名して発行するトークン。[用語](../../architecture/README.md#用語)） | タスクの登録で、登録者の ID として保存する |
| `X-User-Name` | 利用者の表示名 | タスクの登録で、登録者の名前として保存する |
| `X-Request-Id` | 入口が付けたリクエストの ID | ログの各行に `requestId` として出す。BFF のログと同じ ID で追える |

登録での用途は [タスクの登録](task-create.md) にある。

# `tasks` 表（API の DB）

この文書は、`api` リポジトリが作る API の DB と、その表 `tasks` の列を記す。API はタスクを保存して返すサービスで、タスクをこの表に保存する。API の全体像は [API の全体像](README.md) にある。

## DB と表の作成

DB は PostgreSQL で、表は `tasks` の 1 つである。API の起動時に、Flyway（DB の表の作成と変更を、バージョンを付けた SQL ファイルで行うツール）が `api/src/main/resources/db/migration/` の SQL をバージョンの順に流す（[仮定 8](../../architecture/README.md#仮定)）。表を変えるときは、既にある SQL ファイルを変えず、次のバージョンの SQL ファイルを足す。

## 列

次の表は、`tasks` 表の列を示す。`X-User-Id` と `X-User-Name` は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）が渡すヘッダーで、中身は [呼び出し元と受け取るヘッダー](callers-and-headers.md) にある。

| 列 | 型 | 空の可否 | 中身 |
|---|---|---|---|
| `id` | `bigint` | 許さない | 主キー。DB が自動で振る |
| `title` | `varchar(100)` | 許さない | タイトル |
| `description` | `varchar(1000)` | 許す | 説明 |
| `due_date` | `date` | 許す | 期限日 |
| `created_by` | `varchar(100)` | 許さない | 登録者の ID（`X-User-Id`）。インデックス `tasks_created_by_idx` がある |
| `created_by_name` | `varchar(100)` | 許さない | 登録者の名前（`X-User-Name`） |
| `created_at` | `timestamptz` | 許さない | 登録日時。DB が今の時刻を入れる |
| `completed_at` | `timestamptz` | 許す | 完了日時。空なら未完了 |

## 保存する個人情報

`tasks` 表に入る個人情報は、登録者の ID（`created_by`）と登録者の名前（`created_by_name`）だけである。API は、メールアドレスを保存しない。行を消す決まりは無く、タスクは無期限に残る。

# API のエラー応答

この文書は、`api` リポジトリが作る API の、エラーの形とステータスコードを記す。API はタスクを保存して返すサービスで、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。エンドポイントごとの処理は、[API の全体像](README.md) の「文書の一覧」にある各文書に書く。

## エラーの形とステータスコード

エラーは、どれも RFC 9457 の Problem Details（エラーの内容を JSON で返す標準の形。`application/problem+json`）で返す。次の表は、ステータスコードごとの条件を示す。

| ステータスコード | 条件 |
|---|---|
| 400 | `POST /api/tasks` の入力が決まりに合わない。ヘッダー `X-User-Id` か `X-User-Name` が無いときも 400 になる（[タスクの登録](task-create.md)） |
| 404 | タスクが無い。`GET /api/tasks/{id}/due-date-info` では、タスクに期限日が無いときも 404 になる（[期限日の補足情報](due-date-info.md)） |
| 502 | 外部サービス（カレンダー API）から補足情報を取れない（[期限日の補足情報](due-date-info.md)） |

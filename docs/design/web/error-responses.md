# エラー応答

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）がエラーを返すときの形と、ステータスコードごとの条件を記す。BFF は、401 を除くエラーを RFC 9457 の Problem Details（エラーの中身を JSON で返す標準の形。`application/problem+json`）で返す。エンドポイントごとにどのステータスコードを返すかは、[BFF と画面の全体像の「文書の一覧」](README.md#文書の一覧) にある各エンドポイントの文書に書く。

## ステータスコードごとの条件

次の表は、ステータスコードごとの条件を示す。契約は、領域同士の API の取り決めで、BFF のものは [bff.yaml](../../../web/openapi/bff.yaml) である（[用語](../../architecture/README.md#用語)）。

| ステータスコード | 条件 |
|---|---|
| 400 | 入力が契約の決まりに合わない。BFF が検証して返す |
| 401 | JWT（IdP が署名して発行するトークン。[用語](../../architecture/README.md#用語)）が無い、または検証に通らない（[JWT の検証](jwt-verification.md)）。401 だけは Problem Details ではなく、本文は空で、応答に `WWW-Authenticate` ヘッダーが付く |
| 403 | 認可 API が操作を拒否した。`detail` は `この操作は許可されていません` で、拒否の理由はログにだけ出す |
| 404 | タスクが無い。`GET /bff/tasks/{id}` だけは、認可 API が閲覧を拒否したときも 404 にする（[タスクの詳細](task-detail.md)） |
| 502 | API または認証 API が 5xx を返した、応答しない、または接続できない。`detail` は `upstream api error` で、相手のエラーの中身は画面に出さない |
| 503 | 認可 API から可否を受け取れない。`detail` は `authorization service unavailable` |
| 相手と同じ 4xx | API または認証 API が 4xx を返した。BFF は、ステータスコードと本文をそのまま返す。認証 API の 409（メールアドレスが登録済み）と 403（現在のパスワードが違う）がこれに当たる |

503 にする条件の細かい扱いは [認可 API への問い合わせの「可否を受け取れない場合の扱い」](authz-decision-call.md#可否を受け取れない場合の扱い) にある。API が補足情報で返す 502 だけは扱いが違い、[タスクの詳細の「API の 502 の扱い」](task-detail.md#api-の-502-の扱い) にある。

## 入力の検証

入力の決まりは契約 [bff.yaml](../../../web/openapi/bff.yaml) に書き、契約から生成したコントローラーのインターフェースと DTO（リクエストと応答の項目を持つクラス）が検証する。生成したコードは `web/bff/src/generated` にある。BFF は、入力が決まりに合わなければ、認可 API、API、認証 API のどれも呼ばずに 400 を返す。

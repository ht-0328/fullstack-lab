# 判定のエンドポイント（`POST /authz/v1/decisions`）

この文書は、`authz` リポジトリが作る認可 API の、呼び出し元と受け取るヘッダー、エンドポイントの処理、判定のログ、エラー応答を記す。認可 API は、主体（操作をしようとしている利用者）、操作、対象を受け取り、その操作をしてよいかを返す API で、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。リクエストと応答の項目は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [authz.yaml](../../../authz/openapi/authz.yaml) にあるので、この文書には書き写さない。

流れは [全体像の「判定」](README.md#判定) の図にある。

## 呼び出し元と受け取るヘッダー

認可 API は、呼び出し元の認証を行わない。BFF が JWT（IdP が署名して発行するトークン。[用語](../../architecture/README.md#用語)）を検証し、その中身から主体を組み立てて渡す前提で、認可 API は渡された主体をそのまま信じる。入口（すべてのリクエストを最初に受けて振り分ける Nginx。[用語](../../architecture/README.md#用語)）の設定 `nginx/snippets/app-locations.conf` には `/authz/` の転送先が無いので、ブラウザから認可 API には届かない。

認可 API は、判定の結果を返すだけで、タスクやアカウントを読み書きしない。DB も持たず、他のサービスも呼ばない。対象の所有者が誰かは、BFF が調べてリクエストの `resource.ownerId` に入れる。

次の表は、BFF が認可 API に渡すヘッダーと、認可 API での用途を示す。利用者の ID やロールはヘッダーではなく、リクエストの本文の `subject` で渡す。

| ヘッダー | 中身 | 認可 API での用途 |
|---|---|---|
| `X-Request-Id` | 入口が付けたリクエストの ID | ログの各行に `requestId` として出す。BFF のログと同じ ID で追える。ヘッダーが無ければ `-` を出す |

## 処理と応答

次の表は、判定のエンドポイントの処理と応答を示す。エラーの形は「エラー応答」の節にある。

| エンドポイント | 処理 | 応答 |
|---|---|---|
| `POST /authz/v1/decisions` | リクエストを契約の型に読み取り、[判定の順序](decision-order.md) で許可か拒否かを決める。決めた結果を 1 行のログに出す | 200 と、許可かどうか（`allowed`）と理由（`reason`）。拒否のときも 200 で返す。リクエストが契約に合わなければ 400 |

認可 API が動いているかを返すエンドポイント（Spring Boot Actuator の `health`。Actuator は、アプリの状態を HTTP で返す Spring Boot の機能）の公開の範囲は、[設定](settings.md) にある。

## 判定のログ

認可 API は、判定のたびに、誰のどの操作を許可または拒否したかを INFO のログに 1 行出す。次の一覧は、ログに出す項目を示す。

- 主体の ID（`subject.id`）と利用者の種別（`subject.userType`）
- 操作（`action`）と対象の所有者（`resource.ownerId`）
- 結果（`allowed`）と理由（`reason`）

理由は、ログと応答の両方に同じ文字列を出す。理由は開発者が判定を追うためのもので、BFF は利用者の画面に出さない。理由に入る文字列は [判定の理由（`reason`）の文字列](reason-strings.md) にある。

## エラー応答

認可 API は、拒否をエラーにしない。拒否は 200 で `allowed` を `false` にして返し、エラーのステータスコードは、判定そのものができないときだけ返す。

エラーは、RFC 9457 の Problem Details の形（`application/problem+json`）で返す。次の表は、ステータスコードごとの条件を示す。

| ステータスコード | 条件 |
|---|---|
| 400 | リクエストが契約に合わない。必須の項目（`subject`、`action`、`resource` など）が無い、または `subject.userType` が `CUSTOMER` と `STAFF` のどちらでもない |

認可 API が応答しない、またはエラーを返したときに操作を止めるかどうかは、認可 API では決められない。BFF が、判定を得られなかった操作を許可せずにエラーで返す。BFF の扱いは [認可 API への問い合わせ（BFF）](../web/authz-decision-call.md) にある。

## テスト

次の表は、`authz` リポジトリの中で確かめることを示す。Karate は、API を HTTP で呼んで確かめるテストである。

| 層 | 場所 | 確かめること |
|---|---|---|
| Karate | `authz/karate/features/decisions.feature`（`authz/compose.test.yaml` で認可 API を起動して実行） | 契約に合わないリクエストが 400 になること |

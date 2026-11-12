# 認可 API の設定

この文書は、`authz` リポジトリが作る認可 API の設定を記す。認可 API は、主体（操作をしようとしている利用者）、操作、対象を受け取り、その操作をしてよいかを返す API である。設定の値を判定でどう使うかは [判定の順序](decision-order.md) にある。

このフォルダの全体と、使う語の意味は [認可 API の全体像](README.md) にある。

## 判定に使う設定

判定に使う操作の一覧は、コードではなく設定 `authz/src/main/resources/application.yml` の `authz` の下にある（[仮定 5](../../architecture/README.md#仮定)）。

次の抜粋は、判定に使う設定を示す。

```yaml
authz:
  staff-role-permissions:
    task-viewer: [ "task:list", "task:read" ]
    task-admin: [ "task:list", "task:read", "task:create", "task:complete" ]
  customer-actions: [ "task:list", "task:read", "task:create", "task:complete", "account:change-password" ]
```

## キーごとに決めること

次の表は、`application.yml` のキーごとに、何を決めるかを示す。表の BFF は画面専用のサーバー側 API、JWT は IdP が署名して発行するトークンである（[用語](../../architecture/README.md#用語)）。

| キー | 決めること |
|---|---|
| `authz.staff-role-permissions` | 社員のロールの名前と、そのロールに許可する操作の一覧。ロールの名前は、BFF が JWT から取り出して `subject.roles` に入れる値と同じにする |
| `authz.customer-actions` | 一般利用者に許可する操作の一覧。`task:create` 以外は、自分が所有者の対象に限って許可する |
| `server.port` | 認可 API が待ち受けるポート。8080 |
| `spring.mvc.problemdetails.enabled` | 入力のエラーを Problem Details（エラーの内容を JSON で返す標準の形）で返すかどうか。有効にしている |
| `management.endpoints.web.exposure.include`、`management.endpoint.health.probes.enabled` | Actuator（アプリの状態を HTTP で返す Spring Boot の機能）のうち公開するエンドポイント。`health` だけを公開し、`readiness` と `liveness` を有効にしている |
| `logging.pattern.level` | ログの各行に `requestId` を出す書式 |

認可 API には、環境変数で渡す設定は無い。接続先も秘密情報も持たないためである。

設定に操作やロールを足す手順は [操作とロールの追加](adding-actions-and-roles.md) にある。

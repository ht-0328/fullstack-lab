# 操作とロールの追加

この文書は、`authz` リポジトリが作る認可 API に操作やロールを足すときに、開発者が変える場所を記す。認可 API は、主体（操作をしようとしている利用者）、操作、対象を受け取り、その操作をしてよいかを返す API である。操作の名前は、契約（領域同士の API の取り決め。[用語](../../architecture/README.md#用語)）の [authz.yaml](../../../authz/openapi/authz.yaml) では自由な文字列なので、開発者は契約を変えずに操作を足せる。

このフォルダの全体と、使う語の意味は [認可 API の全体像](README.md) にある。

## 変える場所

次の一覧は、足すものごとに、開発者が変える場所を示す。設定のキーの中身は [設定](settings.md) にある。

- 社員に操作を足すとき、開発者は `authz.staff-role-permissions` の該当するロールの一覧に操作の名前を足す
- 一般利用者に操作を足すとき、開発者は `authz.customer-actions` に操作の名前を足す。足した操作は、自分が所有者の対象に限って許可される
- ロールを足すとき、開発者は `authz.staff-role-permissions` にロールの名前と操作の一覧を足す。社員にそのロールを付けるのは IdP（ログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）の側で行う
- 所有者を見ずに一般利用者へ許可する操作（今は `task:create` だけ）を足すときは、設定だけでは足りない。開発者は `authz/src/main/kotlin/com/example/fullstacklab/authz/Policy.kt` の判定を変える

## 合わせて変えるテストと呼び出し側

どの場合も、開発者は `authz/karate/features/decisions.feature` に、足した操作の許可と拒否の行を足す。Karate は、API を HTTP で呼んで確かめるテストである。BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）の側では、BFF の開発者が、足した操作の名前で認可 API に問い合わせる処理を足す。

今の操作とロールごとの可否は [操作ごとの可否](action-permissions.md) にある。

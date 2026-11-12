# 操作ごとの可否

この文書は、`authz` リポジトリが作る認可 API が、操作ごとに誰へ許可を返すかを記す。認可 API は、主体（操作をしようとしている利用者）、操作、対象を受け取り、その操作をしてよいかを返す API で、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）からだけ呼ばれる。可否を決める順序は [判定の順序](decision-order.md) に、可否の元になる設定は [設定](settings.md) にある。

このフォルダの全体と、使う語の意味は [認可 API の全体像](README.md) にある。

## 可否の表

次の表は、設定にある操作のすべてについて、利用者の種別ごとの可否を示す。社員の列の `task-viewer` と `task-admin` は、社員に付けるロール（権限の名前）である。

| 操作 | 意味 | 一般利用者 | 社員 `task-viewer` | 社員 `task-admin` |
|---|---|---|---|---|
| `task:list` | タスクの一覧を見る | 自分のタスクだけ | 可 | 可 |
| `task:read` | タスクの詳細を見る | 自分のタスクだけ | 可 | 可 |
| `task:create` | タスクを登録する | 可 | 不可 | 可 |
| `task:complete` | タスクを完了にする | 自分のタスクだけ | 不可 | 可 |
| `account:change-password` | パスワードを変える | 自分のアカウントだけ | 不可 | 不可 |
| 設定に無い操作（例: `task:delete`） | — | 不可 | 不可 | 不可 |

## 可否の条件と、社員に付けない操作の理由

表の「自分のタスクだけ」「自分のアカウントだけ」は、`resource.ownerId` が `subject.id` と同じときだけ許可することを指す。`resource.ownerId` が空のときと、社員が複数のロールを持つときの扱いは [判定の順序](decision-order.md) にある。BFF は、一般利用者の一覧では `resource.ownerId` に本人の ID を入れて問い合わせる。

`account:change-password` を社員のどのロールにも付けないのは、社員のアカウントを、このシステムの外にある社員用の IdP（ログインを受け付けてトークンを発行するサービス。[用語](../../architecture/README.md#用語)）が管理するためである。

## テスト

次の表は、`authz` リポジトリの中で確かめることを示す。Karate は、API を HTTP で呼んで確かめるテストである。

| 層 | 場所 | 確かめること |
|---|---|---|
| Karate | `authz/karate/features/decisions.feature`（`authz/compose.test.yaml` で認可 API を起動して実行） | 「可否の表」の節の表の主な組み合わせ（一般利用者の本人と他人、`task-viewer` の閲覧の許可と登録、完了の拒否、`task-admin` の登録と完了の許可）。`account:change-password` が一般利用者の本人だけに許可され、社員には拒否されること |

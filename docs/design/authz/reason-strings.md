# 判定の理由（`reason`）の文字列

この文書は、`authz` リポジトリが作る認可 API が、判定の理由として返す文字列を記す。認可 API は、主体（操作をしようとしている利用者）、操作、対象を受け取り、その操作をしてよいかを返す API である（[用語](../../architecture/README.md#用語)）。理由は応答とログの両方に同じ文字列で出し、その扱いは [判定のエンドポイント](decision-endpoint.md) にある。

このフォルダの全体と、使う語の意味は [認可 API の全体像](README.md) にある。

## 文字列の一覧

次の表は、応答とログの `reason` に入る文字列を示す。`{操作}` には `action` の値が入る。`{ロール}` には `subject.roles` の値が、角括弧で囲み、カンマと空白で区切った形（例: `[task-viewer]`。空なら `[]`）で入る。結果を決める順序は [判定の順序](decision-order.md) にある。

| 結果 | 利用者の種別と条件 | `reason` |
|---|---|---|
| 許可 | 社員 | `staff role grants {操作}` |
| 拒否 | 社員 | `no staff role grants {操作} (roles={ロール})` |
| 拒否 | 一般利用者（操作が設定 `customer-actions`（一般利用者に許可する操作の一覧）に無い） | `customers cannot {操作}` |
| 許可 | 一般利用者（`task:create`） | `customers can create their own tasks` |
| 許可 | 一般利用者（所有者が本人） | `customer owns the resource` |
| 拒否 | 一般利用者（所有者が本人でない、または空） | `customer can only {操作} own resources` |

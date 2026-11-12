# CurrentUser

この文書は、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）の中で使う利用者情報 `CurrentUser` の作り方を記す。`CurrentUserFactory` は、検証済みの JWT（IdP が署名して発行するトークン。[用語](../../architecture/README.md#用語)）から `CurrentUser` を作る。発行元ごとのクレーム（JWT に含まれる項目）の違いはここでそろえ、これより後の処理は発行元を意識しない。

このフォルダの全体と、使う語の意味は [BFF と画面の全体像](README.md) にある。

JWT の検証と、発行元ごとの設定は [JWT の検証](jwt-verification.md) にある。

## 項目と値の出所

次の表は、`CurrentUser` の項目と、その値の出所を示す。

| 項目 | 値の出所 |
|---|---|
| `id` | JWT の `sub`。無ければエラーにする |
| `name` | 発行元の設定の `name-claim` が指すクレーム。既定は `preferred_username`。クレームが無ければ `sub` の値を使う |
| `userType` | JWT の `iss` と一致した発行元の設定の `user-type` |
| `roles` | 発行元の設定の `roles-claim` が指す配列。`.` で区切ったパスで、入れ子のクレームをたどる。クレームが無ければ空にする |

## テスト

次の表は、`CurrentUser` について確かめることを示す。単体テストの動かし方は [API、認可 API、認証 API の呼び出しの「テスト」](upstream-clients.md#テスト) にある。

| 層 | 場所 | 確かめること |
|---|---|---|
| 単体 | `web/bff/src/test/` の `CurrentUserFactoryTest` | `realm_access.roles` と `groups` という場所の違うロールのクレームから、同じ形の `CurrentUser` を作ること |

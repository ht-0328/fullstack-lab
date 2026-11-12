# 評価の記録: docs/design/authz/

| 項目 | 内容 |
|---|---|
| 対象 | [docs/design/authz/](../design/authz/README.md) の文書すべて |
| 最終評価日 | 2026-11-12 |
| doc-review の結果 | 合格（3 回目で要修正 0 件） |
| design-review の結果 | 不一致 2 件（文書を直した。2026-11-12） |

## doc-review

次の表は、評価を回すたびに 1 行足す。「主な指摘」は決まりの番号で書き、提案があれば件数と反映したかどうかを添える。1 回目と 2 回目（決まりを変えたあと）は全文評価、3 回目は差分評価。評価は `docs/design/api/` と同じ回にまとめて行った。

### 回ごとの結果

| 回 | 要修正 | 直した | 残した | 主な指摘 |
|---|---|---|---|---|
| 1 | 7 | 7 | 0 | W-2 ×4（契約）、F-3（図にした順序の言い直し）、W-6、F-5。提案 9 件はすべて反映 |
| 2 | 3 | 3 | 0 | 2026-11-12 の決まりの変更（語の一言、言い回し、見出しの揃え方）を受けた全文評価。F-3 ×3（見出し「エンドポイント」、列名「認可 API での使い方」、見出し「表の読み方」）。提案 3 件のうち 2 件を反映（個別の文書に残る一言を省く提案は反映していない） |
| 3 | 0 | 0 | 0 | 合格。2 回目の要修正 3 件は直っていた。提案 1 件は反映した |

### 指摘の一覧

次の表は、回ごとの要修正を 1 行ずつ示す。次の回の評価で、直したはずの指摘を照合するために使う。

| 回 | 決まり | 場所 | 直したか |
|---|---|---|---|
| 1 | W-2 | `README.md` の導入の 4 文目（契約） | 直した |
| 1 | W-6 | `adding-actions-and-roles.md` の導入の 1 文目（文として読めない） | 直した |
| 1 | W-2 | `adding-actions-and-roles.md` の導入の 3 文目（契約） | 直した |
| 1 | W-2 | `decision-order.md` の導入の 3 文目（契約） | 直した |
| 1 | F-3 | `decision-order.md` の「順序」の番号付きの箇条書きと図のリード（図の順序の言い直し） | 直した |
| 1 | W-2 | `decision-endpoint.md` の導入の 3 文目（契約） | 直した |
| 1 | F-5 | `reason-strings.md` の導入（architecture にも索引にもリンクが無い） | 直した |
| 2 | F-3 | `decision-endpoint.md` の見出し「エンドポイント」 | 直した |
| 2 | F-3 | `decision-endpoint.md` の「呼び出し元と受け取るヘッダー」の表の列名「認可 API での使い方」 | 直した |
| 2 | F-3 | `action-permissions.md` の見出し「表の読み方」 | 直した |

### 残した指摘

次の表は、直さずに残した指摘と、その理由。

| 決まり | 場所 | 指摘 | 残す理由 |
|---|---|---|---|

残した指摘は無い。

### 決まり側の課題

`docs/design/api/` と同じ回の評価で挙がったものは、[docs/design/api/ の記録](docs-design-api.md)の「決まり側の課題」にある。次は、このフォルダの文書で挙がったもの。

- 変更の手順を書いた文書（`adding-actions-and-roles.md`）を、設計の文書の単位として認めるか → 2026-11-12 の決まりの更新で解消（1 本に 1 つ）
- 設定の抜粋の値（`settings.md`）と、そこから導いた可否の表（`action-permissions.md`）が、W-9 の同じ事実に当たるか。可否の表は architecture の「操作 × 利用者」の表とも重なる → architecture との重なりは [#43](https://github.com/ht-0328/fullstack-lab/issues/43)
- ヘッダーの表の列名「〜での使い方」が、ほかのフォルダにも同じ違反を生んでいる → 2026-11-12 の決まりの更新で解消（言い回し）

## design-review

次の表は、文書の節ごとに、期待と実装の状態を突き合わせた結果。README、`decision-endpoint.md`、`decision-order.md`、`settings.md`、`adding-actions-and-roles.md` は実装と一致した。照合はコードと設定の読み取りだけで行った。

| 項目（ファイル名と節） | 期待 | 実装の状態 | 判定 | 根拠 |
|---|---|---|---|---|
| `reason-strings.md` の「文字列の一覧」のリードと、社員の拒否の行 | `{ロール}` には `subject.roles` の値が入る | `Set<String>` をそのまま埋め込むので、角括弧付きのカンマ区切り（例: `roles=[task-viewer]`。空なら `roles=[]`）になる | 不一致（文書を直した） | `authz/src/main/kotlin/com/example/fullstacklab/authz/Policy.kt` の 31 行目 |
| `action-permissions.md` の「テスト」の表の Karate の行 | Karate が、可否の表のとおりに判定することを確かめる | 確かめているのは表の一部の組み合わせである | 不一致（文書を直した） | `authz/karate/features/decisions.feature` の 14〜29 行目、38〜41 行目 |

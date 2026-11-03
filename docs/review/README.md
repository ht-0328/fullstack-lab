# 評価の記録

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-11-01 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-11-04 |
| 想定読者（宛先） | 文書を直す人、書き方の決まりと評価エージェントを育てる人 |
| この文書を読んだあと読者ができること | 文書ごとの評価の経過と残った指摘が分かり、どの文書でも繰り返される指摘から、直すべき決まりやテンプレートを見つけられる |

評価エージェント（Claude Code のサブエージェント。文書やコードを読み、決まりや設計とのずれを指摘だけ返す。定義は [doc-review](../../.claude/agents/doc-review.md) と [design-review](../../.claude/agents/design-review.md)）の結果を、文書 1 本につき 1 ファイルで残す場所です。文書を直す人は、直さずに残した指摘をここで確かめます。決まりを育てる人は、どの文書でも出る指摘をここで見つけます。そうした指摘は文書ではなく決まりかテンプレートの側に原因があるので、それらを直す材料にします。

ここでいう決まりは [docs の「書き方」](../README.md#書き方人が読める文書にする決まり)と[「形式の決まり」](../README.md#形式の決まり)、テンプレートは[設計書](../design/TEMPLATE.md)と [ADR](../adr/TEMPLATE.md)（Architecture Decision Record。方針とその理由の記録）の型です。人が PR で行うレビューは、PR のコメントと修正コミットが記録なので、ここには残しません。

## 置く結果

次の表は、ここに結果を置く 2 つのエージェントと、何を確かめるかを示します。

| エージェント | 確かめること | 対象 |
|---|---|---|
| `doc-review` | [書き方の決まり](../README.md#書き方人が読める文書にする決まり)と[形式の決まり](../README.md#形式の決まり)どおりに書けているか | docs のすべての文書 |
| `design-review` | [設計書](../design/README.md)どおりに実装されているか | 設計書だけ。設計書の状態を「実装済み」にするとき（[書く順番](../README.md#書く順番)の 6）に回す |

## ファイル名

対象の文書の、集約リポジトリ（このリポジトリ fullstack-lab）のルートからのパスの `/` を `-` に変え、このフォルダに置きます。`docs/` を省くと、`docs/README.md` の記録のファイル名が `README.md` になり、このフォルダの説明であるこの文書と同じ名前になってしまうので、`docs/` も含めます。次の表は、対象ごとの記録のファイル名の例です。

| 対象 | 記録 |
|---|---|
| `docs/design/0004-task-completion.md` | `docs/review/docs-design-0004-task-completion.md` |
| `docs/adr/ADR-0001-nuxt-generates-types-only.md` | `docs/review/docs-adr-ADR-0001-nuxt-generates-types-only.md` |
| `docs/architecture/README.md` | `docs/review/docs-architecture-README.md` |
| `docs/README.md` | `docs/review/docs-README.md` |

## 記録の形

次の形で書きます。評価を回すたびに「回ごとの結果」に 1 行足し、その回の要修正を「指摘の一覧」に 1 行ずつ（回、決まり、場所、直したか）足します。次の回の評価で、直したはずの指摘を 1 件ずつ照合するためです。

提案（doc-review が返す指摘のうち、合否に数えないもの）は、次の回で照合しないので、件数と反映したかどうかだけを「回ごとの結果」の「主な指摘」の列に書き、場所は残しません。

設計書でない文書は、「design-review」の節に「該当しない。」とだけ書きます。

記録の形を変えても、「回ごとの結果」と「指摘の一覧」に既に書いた行は書き換えません。行はその回の評価の結果そのものなので、後から形を変えると、そのときの指摘と照合できなくなるためです。次にその文書を評価するときは、足す行から新しい形で書き、無い節があれば足します。「残した指摘」と「決まり側の課題」は、記録の形を変えたかどうかにかかわらず、評価のたびに書き換えて最新にします。

```markdown
# 評価の記録: docs/design/0004-task-completion.md

| 項目 | 内容 |
|---|---|
| 対象 | [docs/design/0004-task-completion.md](../design/0004-task-completion.md) |
| 最終評価日 | YYYY-MM-DD |
| doc-review の結果 | 合格（2 回目で要修正 0 件） |
| design-review の結果 | 不一致なし（YYYY-MM-DD） |

## doc-review

次の表は、評価を回すたびに 1 行足す。「主な指摘」は決まりの番号で書き、提案があれば件数と反映したかどうかを添える。

### 回ごとの結果

| 回 | 要修正 | 直した | 残した | 主な指摘 |
|---|---|---|---|---|
| 1 | 7 | 7 | 0 | W-1、W-3 ×4、W-5 ×2。提案 3 件はすべて反映 |
| 2 | 0 | 0 | 0 | 合格 |

### 指摘の一覧

| 回 | 決まり | 場所 | 直したか |
|---|---|---|---|
| 1 | W-3 | 「認可」の表の前 | 直した |

### 残した指摘

次の表は、直さずに残した指摘と、その理由。

| 決まり | 場所 | 指摘 | 残す理由 |
|---|---|---|---|

### 決まり側の課題

判定できなかった決まりや、他の文書でも出る指摘を箇条書きにする。決まりの更新で解消したものには「→ YYYY-MM-DD の決まりの更新で解消」と添える。

## design-review

次の表は、設計書の節ごとに、期待と実装の状態を突き合わせた結果。

| 項目（設計書の節） | 期待 | 実装の状態 | 判定 | 根拠 |
|---|---|---|---|---|
```

## 止める条件

文書を書いた AI エージェントは、スキル（AI エージェント向けの手順書）[writing-docs](../../.agents/skills/writing-docs/SKILL.md) に従い、要修正が 0 件になるか、前回と同じ指摘が残って減らなくなったら、評価と修正を止めます。減らない指摘は直さずに「残した指摘」に理由を書き、PR 本文にその件数を書いて、人のレビューに判断を委ねます。

評価は、1 回目と決まりを変えたあとは全文評価にし、その次の回からは、前回の要修正の箇所と前回から変えた行だけを見る差分評価にします。毎回全文を読み直すと、前の回で見ていなかった箇所から新しい指摘が出続けて終わらないためです。評価の途中では決まりを変えず、変えたときは影響する文書を全文評価し直します。

決まりを変えて全文評価し直すときも、回の番号は 1 に戻さず、前の回から続けて振ります。「指摘の一覧」は回の番号で行を照合するので、番号が重なると、どの評価の指摘か分からなくなるためです。「合格までの回数の実績」の回数と、その節にある人に渡す目安の 5 回は、回の番号ではなく、1 回目か、決まりを変えたあとの全文評価から数えます。

決まりを書いた docs/README.md 自身は、指摘を直すことがそのまま決まりを変えることになるので、決まりを変えても全文評価し直さずに差分評価で回し、合格したあとに 1 回だけ全文評価します（スキル [writing-docs](../../.agents/skills/writing-docs/SKILL.md) の「決まりを育てる」）。そのため、差分評価で回す間は人に渡す目安を当てはめず、合格したあとのその全文評価から数えます。

## 合格までの回数の実績

次の表に、文書ごとに合格までにかかった回数を残します。2026-11-02 に 14 本を評価したときは、すべて 2〜5 回目で合格しました。この実績から、5 回を超えても合格しないときは決まりかテンプレートに原因があるとみて人に渡す、と決めました（スキル [writing-docs](../../.agents/skills/writing-docs/SKILL.md) の「止める」）。4 回目以降の多くは、2 回目以降を差分評価にする前の全文評価で、前の回では読んでいなかった箇所から出た指摘でした。

| 文書 | 回数 | 残した指摘 | 日付 |
|---|---|---|---|
| [docs/adr/README.md](../adr/README.md) | 2 | 0 | 2026-11-02 |
| [docs/review/README.md](README.md) | 2 | 0 | 2026-11-02 |
| [docs/design/README.md](../design/README.md) | 2 | 0 | 2026-11-02 |
| [docs/design/0002-authentication-authorization.md](../design/0002-authentication-authorization.md) | 3 | 0 | 2026-11-02 |
| [docs/design/0003-contracts-and-repositories.md](../design/0003-contracts-and-repositories.md) | 3 | 0 | 2026-11-02 |
| [docs/adr/ADR-0001-nuxt-generates-types-only.md](../adr/ADR-0001-nuxt-generates-types-only.md) | 3 | 0 | 2026-11-02 |
| [docs/roadmap/README.md](../roadmap/README.md) | 4 | 0 | 2026-11-02 |
| [docs/architecture/README.md](../architecture/README.md) | 4 | 4 | 2026-11-02 |
| [docs/README.md](../README.md) | 4 | 0 | 2026-11-02 |
| [docs/design/0001-task-management.md](../design/0001-task-management.md) | 4 | 0 | 2026-11-02 |
| [docs/design/0004-task-completion.md](../design/0004-task-completion.md) | 4 | 1 | 2026-11-02 |
| [docs/design/0005-auth-api-and-signup.md](../design/0005-auth-api-and-signup.md) | 5 | 2 | 2026-11-02 |
| [docs/adr/ADR-0002-distribute-clients-as-artifacts.md](../adr/ADR-0002-distribute-clients-as-artifacts.md) | 5 | 0 | 2026-11-02 |
| [docs/adr/ADR-0003-commit-generated-code.md](../adr/ADR-0003-commit-generated-code.md) | 5 | 0 | 2026-11-02 |
| [docs/design/0006-aws-foundation-and-ecr.md](../design/0006-aws-foundation-and-ecr.md) | 3 | 0 | 2026-11-03 |
| [docs/adr/ADR-0004-run-aws-tools-in-docker.md](../adr/ADR-0004-run-aws-tools-in-docker.md) | 4 | 0 | 2026-11-03 |
| [docs/adr/ADR-0005-infra-tools-container.md](../adr/ADR-0005-infra-tools-container.md) | 3 | 0 | 2026-11-03 |
| [docs/adr/README.md](../adr/README.md) | 1 | 2 | 2026-11-04 |
| [docs/adr/ADR-0004-run-aws-tools-in-docker.md](../adr/ADR-0004-run-aws-tools-in-docker.md) | 1 | 0 | 2026-11-04 |
| [docs/adr/ADR-0002-distribute-clients-as-artifacts.md](../adr/ADR-0002-distribute-clients-as-artifacts.md) | 1 | 0 | 2026-11-04 |
| [docs/design/0001-task-management.md](../design/0001-task-management.md) | 2 | 0 | 2026-11-04 |
| [docs/design/0002-authentication-authorization.md](../design/0002-authentication-authorization.md) | 2 | 0 | 2026-11-04 |
| [docs/design/0003-contracts-and-repositories.md](../design/0003-contracts-and-repositories.md) | 2 | 0 | 2026-11-04 |
| [docs/design/0004-task-completion.md](../design/0004-task-completion.md) | 2 | 1 | 2026-11-04 |
| [docs/design/0005-auth-api-and-signup.md](../design/0005-auth-api-and-signup.md) | 2 | 6 | 2026-11-04 |
| [docs/design/0006-aws-foundation-and-ecr.md](../design/0006-aws-foundation-and-ecr.md) | 2 | 0 | 2026-11-04 |
| [docs/adr/ADR-0001-nuxt-generates-types-only.md](../adr/ADR-0001-nuxt-generates-types-only.md) | 2 | 0 | 2026-11-04 |
| [docs/adr/ADR-0003-commit-generated-code.md](../adr/ADR-0003-commit-generated-code.md) | 2 | 0 | 2026-11-04 |
| [docs/adr/ADR-0005-infra-tools-container.md](../adr/ADR-0005-infra-tools-container.md) | 2 | 0 | 2026-11-04 |
| [docs/architecture/README.md](../architecture/README.md) | 3 | 0 | 2026-11-04 |
| [docs/roadmap/README.md](../roadmap/README.md) | 3 | 0 | 2026-11-04 |
| [docs/README.md](../README.md) | 4 | 0 | 2026-11-04 |

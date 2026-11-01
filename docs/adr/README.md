# 決定の記録（ADR）

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-11-01 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-11-01 |
| 想定読者（宛先） | 方針に従って変更する開発者（人と AI） |
| この文書を読んだあと読者ができること | 今有効な方針を一覧でき、理由を書いた ADR を探せる |

複数の変更にまたがって従う方針と、その理由を 1 件 1 本で記録します。設計書との使い分けは [../README.md](../README.md#設計書と-adr-の使い分け)、書き方は [TEMPLATE.md](TEMPLATE.md) にあります。

## 索引

| 番号 | 題名 | 状態 | 関係する設計書 |
|---|---|---|---|
| [ADR-0001](ADR-0001-nuxt-generates-types-only.md) | 画面（Nuxt）は OpenAPI から型だけを生成し、HTTP の層は生成しない | 採用 | [0003](../design/0003-contracts-and-repositories.md) |
| [ADR-0002](ADR-0002-distribute-clients-as-artifacts.md) | 領域間のクライアントは成果物（Maven）として配布し、ソースを共有しない | 採用 | [0003](../design/0003-contracts-and-repositories.md) |
| [ADR-0003](ADR-0003-commit-generated-code.md) | OpenAPI から生成したコードは git で管理する | 採用 | [0003](../design/0003-contracts-and-repositories.md) |

状態: 採用 → 廃止。廃止するときは本文を変えず、新しい ADR を書いて、古い ADR の状態を「廃止（ADR-NNNN で置き換え）」にします。

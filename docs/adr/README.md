# 決定の記録（ADR）

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-11-01 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-11-03 |
| 想定読者（宛先） | 方針に従ってコードや構成を変える開発者（人と AI） |
| この文書を読んだあと読者ができること | 今有効な方針を一覧でき、理由を書いた ADR を探せる |

この文書は、決定の記録（ADR。Architecture Decision Record）の索引で、今ある ADR を一覧にします。ADR は、設計の文書 1 本（作るもの 1 つ）の中で閉じず、他の変更にも従わせたい方針を、その理由とともに方針 1 件につき 1 本で記録する文書です。設計の文書との使い分けは docs の README の[「設計の文書と ADR の使い分け」](../README.md#設計の文書と-adr-の使い分け)、節構成と書き方の例は [ADR のテンプレート](TEMPLATE.md)、書き方の決まりは docs の README の[「書き方」](../README.md#書き方人が読める文書にする決まり)にあります。

## 索引

次の表は、今ある ADR を番号順に示します。「関係する設計の文書」は、その方針に従って作るものを書いた文書です。設計の文書の一覧は[設計の文書の索引](../design/README.md)にあります。

| 番号 | 題名 | 状態 | 関係する設計の文書 |
|---|---|---|---|
| [ADR-0001](ADR-0001-nuxt-generates-types-only.md) | 画面（Nuxt）は OpenAPI から型だけを生成し、HTTP の層は生成しない | 採用 | [契約からのコード生成](../design/shared/code-generation.md) |
| [ADR-0002](ADR-0002-distribute-clients-as-artifacts.md) | 領域間のクライアントは成果物（Maven）として配布し、ソースを共有しない | 採用 | [生成クライアントの publish と取得](../design/shared/client-distribution.md) |
| [ADR-0003](ADR-0003-commit-generated-code.md) | OpenAPI から生成したコードは git で管理する | 採用 | [契約からのコード生成](../design/shared/code-generation.md)、[check-generated](../design/shared/check-generated.md) |
| [ADR-0004](ADR-0004-run-aws-tools-in-docker.md) | AWS CLI と Terraform はホストに入れず、Docker のコンテナで動かす | 廃止（[ADR-0005](ADR-0005-infra-tools-container.md) で置き換え） | [道具のコンテナ](../design/infra/tools-container.md) |
| [ADR-0005](ADR-0005-infra-tools-container.md) | AWS CLI と Terraform は 1 つの道具のコンテナに入れ、中に入って公式どおりのコマンドで使う | 採用 | [道具のコンテナ](../design/infra/tools-container.md) |

状態は「採用」か「廃止」で、「採用」のものが今有効な方針です。方針を覆すときは、作成者（文書を書き、方針を決める人。ht-0328）が新しい ADR を書き、古い ADR の状態を「廃止（ADR-NNNN で置き換え）」にします。古い ADR の決定の中身は変えません（認める修正は、docs の README の[「種類と置き場所」](../README.md#種類と置き場所)の adr/ の行にあります）。古い ADR を書き換えずに残すのは、ADR が「なぜその方針にしたか」に答える記録で、決めた当時の判断と理由を後から読めるようにするためです。

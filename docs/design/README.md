# 設計書

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-10-28 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-11-01 |
| 想定読者（宛先） | 機能を追加・変更する開発者（人と AI） |
| この文書を読んだあと読者ができること | 設計書の置き場所と流れが分かり、既存の設計書を探せる |

この文書は、設計書の索引です。設計書は、機能の追加・変更を実装する前に、何をどう作るかを決める文書で、変更 1 件につき 1 本をこのフォルダに置きます。設計書と ADR（Architecture Decision Record。方針とその理由の記録。[ADR の索引](../adr/README.md)）の使い分けは、[docs の「設計書と ADR の使い分け」](../README.md#設計書と-adr-の使い分け)にあります。

設計書は[テンプレート](TEMPLATE.md)の節構成で書き、例には直近の [0005 認証 API と会員登録](0005-auth-api-and-signup.md)を使います。AI に書かせるときは、スキル [writing-design-doc](../../.agents/skills/writing-design-doc/SKILL.md)（AI エージェント向けの手順書。一覧は [AGENTS.md](../../AGENTS.md) の表）を使います。

## 設計書を書いてから実装するまでの流れ

設計書を書いてから実装に反映するまでの順番と、各段で行うことは、[docs の「書く順番」](../README.md#書く順番)の 2〜5 にあります。次の表は、その各段で AI に使わせるスキルとエージェント（評価だけを返すサブエージェント。[用語](../architecture/README.md#用語)）を示します。「契約」は、リポジトリ同士の API の取り決め（各リポジトリの `openapi/*.yaml`）です。

| 書く順番 | 段 | スキル・エージェント |
|---|---|---|
| 2 | 設計書を書き、未決事項が無くなったら状態を「承認」にする | スキル `writing-design-doc` |
| 3 | 書いた設計書を評価し、要修正が 0 件になるまで直す | スキル `writing-docs`、エージェント `doc-review` |
| 4 | 設計書の「実装の段取り」に沿って実装し、PR を出す。契約を変えるなら、`updating-openapi-contract` の順序に従う | スキル `implementing-from-design`、`updating-openapi-contract`、`pr-and-commit` |
| 5 | マージ後、設計書に「実装 PR」を書いて状態を「実装済み」にし、設計と実装のずれを確かめる | エージェント `design-review` |

## 索引

次の表は、これまでに書いた設計書を番号順に並べ、状態と影響するリポジトリを示します。「集約」は、集約リポジトリ（このリポジトリ fullstack-lab）を指します。

| 番号 | 題名 | 状態 | 影響するリポジトリ |
|---|---|---|---|
| [0001](0001-task-management.md) | タスク管理（一覧・登録・詳細、外部サービスの補足情報） | 実装済み | web, api, authz, 集約 |
| [0002](0002-authentication-authorization.md) | 認証と認可（ALB 相当の前段認証、2 つの IdP、JWT、認可 API） | 実装済み | web, authz, 集約 |
| [0003](0003-contracts-and-repositories.md) | 契約（OpenAPI）とリポジトリ分割、クライアントの配布 | 実装済み | web, api, authz, 集約 |
| [0004](0004-task-completion.md) | タスクの完了 | 実装済み | web, api, authz, 集約 |
| [0005](0005-auth-api-and-signup.md) | 認証 API と会員登録（独立リポジトリの認証 API、Keycloak のユーザー管理、公開パス） | 実装済み | auth（新規）, authz, web, 集約 |

状態は「提案」から始まり、未決事項が無くなったら「承認」、実装の PR がマージされたら「実装済み」に進みます。廃止した設計書も索引から消さず、状態を「廃止」にして理由を書きます。過去にどんな案があり、なぜやめたかを辿れるようにするためです。

## 関連

次の文書は、設計書を書く・探すときに合わせて開くものです。

- 構成全体と仮定: [architecture](../architecture/README.md)
- 文書の種類と置き場所、書く順番、設計書と ADR の使い分け: [docs の README](../README.md)
- 決定の記録: [ADR の索引](../adr/README.md)

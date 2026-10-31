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

機能の追加・変更は、ここに設計書を書いてから実装します。書き方は既存の設計書（直近は [0005](0005-auth-api-and-signup.md)）と同じ節構成にし、AI に書かせるときはスキル `writing-design-doc` を使います。

## 流れ

1. **設計書を書く**（`writing-design-doc`）。未決事項はユーザーに質問として出す
2. 未決事項がなくなったら状態を「承認」にする
3. **実装する**（`implementing-from-design`）。契約を変えるなら `updating-openapi-contract` の順序で
4. PR を出す（`pr-and-commit`）。マージ後、設計書に「実装 PR」を追記し、状態を「実装済み」にする
5. `design-review` エージェントで設計書と実装のずれを確かめる

## 索引

| 番号 | 題名 | 状態 | 影響するリポジトリ |
|---|---|---|---|
| [0001](0001-task-management.md) | タスク管理（一覧・登録・詳細、外部サービスの補足情報） | 実装済み | web, api, authz, 集約 |
| [0002](0002-authentication-authorization.md) | 認証と認可（ALB 相当の前段認証、2 つの IdP、JWT、認可 API） | 実装済み | web, authz, 集約 |
| [0003](0003-contracts-and-repositories.md) | 契約（OpenAPI）とリポジトリ分割、クライアントの配布 | 実装済み | web, api, authz, 集約 |
| [0004](0004-task-completion.md) | タスクの完了 | 実装済み | web, api, authz, 集約 |
| [0005](0005-auth-api-and-signup.md) | 認証 API と会員登録（独立リポジトリの認証 API、Keycloak のユーザー管理、公開パス） | 実装済み | auth（新規）, authz, web, 集約 |

状態: 提案 → 承認 → 実装済み。廃止した設計書は索引に残し、状態を「廃止」にして理由を書きます。

## 関連

- 構成全体と仮定: [../architecture.md](../architecture.md)
- 決定の記録（ADR）: [../adr/](../adr/)

---
name: implementing-from-design
description: >-
  docs/design/ の設計書に沿って fullstack-lab の機能を実装し、テストし、PR を出すまでを進める。
  「設計書 NNNN を実装して」「docs/design/xxx.md のとおりに作って」と頼まれたときに使う。
  設計書が無い、または未決事項が残っているときは、先に writing-design-doc で設計書を整える。
---

# 設計書から実装する

## 1. 着手前

1. 設計書を読み、状態が「承認」で、「未決事項」が空であることを確かめます。どちらかを満たさなければ実装せず、ユーザーに確認します。課題の issue（集約リポジトリ）を探し、無ければ [writing-design-doc](../writing-design-doc/SKILL.md) の手順 0 で起票します。「実装の段取り」の節があれば、その順で進めます（無ければ次の表の順）。
2. 「影響するリポジトリ」に挙がったリポジトリごとに、main を最新にしてブランチを切ります（サブモジュールの中でも `git -C <dir> checkout -b ...`）。
3. 「契約の変更」があれば、`updating-openapi-contract` の順序で先に提供側を進めます。

## 2. 実装の順序

依存の下流から上流へ進めると、各段で動かして確かめられます。

| 順 | リポジトリ | 主な変更 | 確認 |
|---|---|---|---|
| 1 | `api` | マイグレーション（`src/main/resources/db/migration/V<n>__*.sql`、既存ファイルは変えない）、業務モデル、リポジトリ、コントローラー（生成インターフェースの実装） | `docker build --target test .`、Karate |
| 2 | `authz` | 新しい操作の権限（`application.yml`）、必要なら `Policy` | `docker build --target test .`、Karate |
| 2' | `auth` | アカウント操作（`CustomerAccountService`、`KeycloakAdminClient`）、realm `customer` の定義（`keycloak/import/`） | `docker build --target test .`、Karate（本物の Keycloak を `compose.test.yaml` で起動） |
| 3 | `web/bff` | クライアントのバージョン追従、`TaskViewService`（認可 → API → 画面向け DTO）、`BffController` | `docker build --target test --network host -f bff/Dockerfile .` |
| 4 | `web/frontend` | 型の再生成、ページ、`useBff()` の呼び出し | `docker build --target typecheck -f frontend/Dockerfile .`、Playwright |
| 5 | 集約 | Compose・Nginx・スモークテスト・ドキュメント、サブモジュールの参照更新 | `./scripts/smoke-test.sh`、`./scripts/e2e-test.sh` |

- 契約を変えたら `./scripts/generate.sh` で生成し直し、生成物（`src/generated`、`client/src/generated`、`frontend/app/types/bff.d.ts`）も同じコミットに含めます（`updating-openapi-contract`）。
- 生成コードを業務ロジックに広げません。API は業務モデルと DTO を `TaskMapping` で、BFF は api-client の DTO と画面向け DTO を `TaskViewService` の中で変換します。
- 認可は「拒否が既定」です。新しい操作は認可 API に問い合わせてから API を呼びます。
- 外部サービスの失敗は縮退、認可 API の失敗は拒否（fail-closed）。この方針を変えるなら設計書に書きます。

## 3. 設計とのずれ

実装中に設計書と違う判断が必要になったら、**黙って実装を変えません。** 設計書の該当箇所を直し、PR 本文の「課題・申し送り事項」に差分と理由を書きます。設計書には「いつ変えたか」を書かず、変えたあとの設計だけを書きます。

## 4. 仕上げ

1. 各リポジトリでテストを実行し、結果を PR 本文の「テスト内容」に書きます（コマンドと、その検証で十分と判断した理由）。
2. `pr-and-commit` に従って PR を出します。PR の概要に `Refs ht-0328/fullstack-lab#<issue の番号>` を書きます。サブモジュールの PR がマージされてから、集約リポジトリの参照更新 PR を出します。段がマージされたら、issue の段取りにチェックを付け、PR へのリンクを書きます。
3. 設計書の先頭に「実装 PR」の行を追加し、設計書と索引の状態を「実装済み」にします（実装の PR がすべてマージされたあと、集約リポジトリの最後の PR で行う）。その PR がマージされたら issue を閉じます。
4. `design-review` エージェントで設計書と実装のずれを確認します。結果は `docs/review/docs-design-NNNN-<slug>.md` の「design-review」の節に書きます（[docs/review/README.md](../../../docs/review/README.md)）。
5. 残課題（後に回したこと、設計とのずれ、design-review で直さなかった指摘、決まっていないこと）があれば、1 つにつき 1 つ issue を起票し（同じ課題の issue があればコメントを足す）、設計書の「課題・申し送り事項」からリンクします。[docs/architecture/](../../../docs/architecture/README.md) と [docs/roadmap/](../../../docs/roadmap/README.md) を今の状態に合わせます。

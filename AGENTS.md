# AGENTS.md

fullstack-lab で作業する AI コーディングエージェント共通のルールです。Claude Code は `AGENTS.md` を自動では読まないため、[CLAUDE.md](CLAUDE.md) が `@AGENTS.md` でこのファイルを取り込みます。仕組みは [.agents/README.md](.agents/README.md) を参照してください。

## このリポジトリについて

- 業務環境に近い構成を学習用に再現したタスク管理アプリです。全体像は [README.md](README.md)、構成と仮定は [docs/architecture.md](docs/architecture.md) にあります。
- 5 つのリポジトリで構成され、ここは集約リポジトリです。`web/`（画面 + BFF）、`api/`、`authz/`、`auth/`（認証 API と Keycloak の realm `customer`）は git submodule で、それぞれ独立した Git リポジトリです。**サブモジュールの中を変更したら、そのリポジトリでブランチを切り、PR を出します。** 集約リポジトリでは参照先のコミットを進める PR を別に出します。
- 領域同士は OpenAPI の契約と publish された成果物だけでつながります。他の領域のソースを直接参照するコードは書きません。
- 業務環境について分かっている事実と、学習用に置いた仮定は [docs/architecture.md の「仮定」](docs/architecture.md#仮定) で分けています。仮定を事実のように書かないでください。

## 設計書から実装する

機能の追加や変更は、設計書（Markdown）を先に書き、それに沿って実装します。

| 段階 | 使うスキル | 成果物 |
|---|---|---|
| 設計書を書く | `writing-design-doc` | `docs/design/NNNN-<slug>.md`（[索引](docs/design/README.md)） |
| 契約を変える | `updating-openapi-contract` | `*/openapi/*.yaml` とバージョン |
| 実装する | `implementing-from-design` | 各リポジトリのコードとテスト |
| 取り込む | `pr-and-commit` | PR（テンプレートに沿った本文）と CI |
| 設計と実装のずれを確かめる | エージェント `design-review` | 指摘の一覧 |

設計書に未決事項が残っているうちは実装を始めません。実装中に設計と違う判断が必要になったら、黙って実装を変えず、設計書を直して差分を報告します。

ドキュメントの書き方は、既存の設計書と ADR を型にします。設計書は直近のもの（[docs/design/0005-auth-api-and-signup.md](docs/design/0005-auth-api-and-signup.md)）、ADR は [docs/adr/ADR-0003-commit-generated-code.md](docs/adr/ADR-0003-commit-generated-code.md) と同じ節構成で書きます。

## 絶対厳守

- **日本語で書く**: 回答、コミットメッセージ、PR 本文、コードコメント、ドキュメントは日本語で書きます（技術用語は英語のままで構いません）。
- **main に直接 push しない**: 4 リポジトリとも main は保護されています。ブランチ → PR → CI が通ってからマージします。
- **秘密情報を出さない**: `.env` の中身、トークン、クライアントシークレットを生成・出力・コミットしません。`.env.example` のダミー値だけを扱います。
- **契約を黙って変えない**: `openapi/*.yaml` を変えるときは `updating-openapi-contract` の手順に従い、`info.version` とビルドのバージョンを同時に上げ、影響する呼び出し側を PR に書きます。
- **生成コードを手で直さない**: OpenAPI から生成したコード（各リポジトリの `src/generated`、`web/frontend/app/types/bff.d.ts`）は git で管理しますが、手で直しません。仕様を直して `./scripts/generate.sh` で生成し直し、生成物も同じコミットに含めます。生成し忘れや手直しは Docker の test / typecheck ステージ（`check-generated`）が落とします（[ADR-0003](docs/adr/ADR-0003-commit-generated-code.md)）。
- **スコープを勝手に広げない**: 依頼されていないファイルを変更しません。判断に迷ったら推測で進めず、ユーザーに確認します。
- **AWS のリソースを作らない**: 費用が発生するため、構成と費用の見込みを示して確認を取ってからにします。

## 変更したら必ず検証する

```bash
./scripts/generate.sh                 # 契約（openapi/*.yaml）を変えたとき（生成し直し、生成物も同じコミットに含める）
./scripts/publish-clients.sh          # api / authz / auth の契約を変えたとき（新しいバージョンを publish）
docker compose up -d --build --wait   # 起動
./scripts/unit-test.sh                # 単体テストと型チェック
./scripts/smoke-test.sh               # 主要な経路（認証・認可・画面・外部連携）
./scripts/api-test.sh                 # Karate（API と認可 API）
./scripts/e2e-test.sh                 # Playwright（画面）
```

サブモジュール単体でも検証できます（各リポジトリの README を参照）。結果は PR 本文の「テスト内容」に、実行したコマンドと、その検証で十分と判断した理由を書きます。

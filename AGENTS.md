# AGENTS.md

fullstack-lab で作業する AI コーディングエージェント共通のルールです。Claude Code は `AGENTS.md` を自動では読まないため、[CLAUDE.md](CLAUDE.md) が `@AGENTS.md` でこのファイルを取り込みます。仕組みは [.agents/README.md](.agents/README.md) を参照してください。

## このリポジトリについて

- 業務環境に近い構成を学習用に再現したタスク管理アプリです。全体像は [README.md](README.md)、構成と仮定は [docs/architecture/](docs/architecture/README.md)、文書の置き場所は [docs/README.md](docs/README.md) にあります。
- 複数のリポジトリで構成され、ここは集約リポジトリです。`web/`（画面 + BFF）、`api/`、`authz/`、`auth/`（認証 API と Keycloak の realm `customer`）、`infra/`（AWS のインフラ。Terraform と道具のコンテナ）は git submodule で、それぞれ独立した Git リポジトリです。**サブモジュールの中を変更したら、そのリポジトリでブランチを切り、PR を出します。** 集約リポジトリでは参照先のコミットを進める PR を別に出します。
- 領域同士は OpenAPI の契約と publish された成果物だけでつながります。他の領域のソースを直接参照するコードは書きません。
- 業務環境について分かっている事実と、学習用に置いた仮定は [docs/architecture/ の「仮定」](docs/architecture/README.md#仮定) で分けています。仮定を事実のように書かないでください。

## 設計の文書から実装する

機能の追加や変更は、集約リポジトリの issue から始め、設計の文書（Markdown）を先に変更後の作りに直し、それに沿って実装します。設計の文書は、設計の文書のフォルダ `docs/design/{web,api,authz,auth,infra,shared}/` に、作るもの 1 つにつき 1 本で置く「今の作り」の文書です（`shared` は領域をまたぐ仕組み）。各フォルダの全体像は `README.md` にあり、案内は [docs/design/README.md](docs/design/README.md) にあります。

| 段階 | 使うスキル | 成果物 |
|---|---|---|
| 課題を起票し、進み具合を追う | `writing-design-doc`、`implementing-from-design`、`writing-docs`、`pr-and-commit` | 集約リポジトリの issue（[課題のテンプレート](.github/ISSUE_TEMPLATE/issue.md)。課題、決めること、やることのチェックリスト） |
| 設計の文書を直す・足す | `writing-design-doc` | `docs/design/<フォルダ>/` の、変わる部分の文書（新しく作るものは 1 本足し、全体像の `README.md` に 1 行足す） |
| 文書を評価して直す | `writing-docs`（エージェント `doc-review`） | 合格した文書と `docs/review/` の記録 |
| 契約を変える | `updating-openapi-contract` | `*/openapi/*.yaml` とバージョン |
| 実装する | `implementing-from-design` | 各リポジトリのコードとテスト |
| 取り込む | `pr-and-commit` | PR（テンプレートに沿った本文）と CI |
| 文書と実装のずれを確かめる | エージェント `design-review` | 指摘の一覧（`docs/review/` に記録） |

issue の「決めること」が残っているうちは実装を始めません。決まったことは設計の文書の本文に書きます。決まっていないこと、作る順序、作業の進み具合（どの段が済んだか）、残課題（後に回したこと、評価で残した指摘）は設計の文書に書かず、issue に書きます。実装中に文書と違う判断が必要になったら、黙って実装を変えず、文書を直して差分を報告します。

設計の文書に書くのは、作るもの 1 つです。1 本に 2 つ目の作るものが混ざったら文書を分け、全体像の `README.md` には細かいこと（値や設定）を書きません。方針とその理由、検討した案の比較は ADR に書きます（[docs/adr/TEMPLATE.md](docs/adr/TEMPLATE.md) の節構成）。文書の種類と置き場所、設計の文書と ADR の使い分けは [docs/README.md](docs/README.md) にあります。書いた文書は `writing-docs` の手順で `doc-review` に評価させ、合格させてから PR を出します。

## 図解ページを書く・直す

人が読む図解（`references/architecture-notes`。HTML、SVG、`assets/notes.css`、README、`index.html`）を作る・直すときは、必ずスキル `writing-architecture-notes` を使います（本体は `references/architecture-notes/.agents/skills/` にあり、ルートのスキルはその入口です）。読者は「新しくチームに入った人」と「まだスキルの無い人」で、ページの決まりは [references/architecture-notes/README.md の「ページの書き方」](references/architecture-notes/README.md#ページの書き方) にあります。変更はそのリポジトリでブランチを切って PR を出し、集約リポジトリでは参照先のコミットを進める PR を別に出します。

## 絶対厳守

- **日本語で書く**: 回答、コミットメッセージ、PR 本文、コードコメント、ドキュメントは日本語で書きます（技術用語は英語のままで構いません）。
- **main に直接 push しない**: 集約リポジトリと `web` / `api` / `authz` / `auth` / `infra` の main は保護されています。ブランチ → PR → CI が通ってからマージします。
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
python3 scripts/doc-lint.py           # docs/ の文書を変えたとき（先頭の表、リンク、段落の文数、用語）
```

サブモジュール単体でも検証できます（各リポジトリの README を参照）。結果は PR 本文の「テスト内容」に、実行したコマンドと、その検証で十分と判断した理由を書きます。

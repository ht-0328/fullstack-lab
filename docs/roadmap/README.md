# AWS・CI/CD ロードマップ

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-10-30 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-11-01 |
| 想定読者（宛先） | AWS 化と CI/CD を進める人、費用を確認する人 |
| この文書を読んだあと読者ができること | フェーズの順序と状態、費用の見込み、着手前に決めることを説明できる |

この文書は、fullstack-lab を AWS に載せ、CI/CD を整える計画です。フェーズの順序と状態、着手前に決めたこと、AWS 化で決める構成（IaC、Nginx の配置、ALB の認証、CI/CD の分担、成果物の置き場）、費用の見込みを、この順に載せます。IaC は AWS の構成をコードで書くこと、Nginx はローカルで入口（すべてのリクエストを最初に受けて振り分けるもの）を担うプロキシ、ALB は AWS のロードバランサーです。

ローカル構成（Docker Compose（以下 Compose）で動く今の構成。[構成図](../architecture/README.md#ローカル環境の構成図)）と CI は、フェーズ 2 までで完了しています。フェーズ 3 から AWS の費用が発生するので、**各フェーズは、作成者（ht-0328）が費用の見込みを確かめて承認してから始めます。** 金額はすべて概算です。実際の判断は [AWS Pricing Calculator](https://calculator.aws/) で確かめてください。

## フェーズ

次の表は、フェーズごとに何を作るか、AWS の費用、今の状態を示します。1〜2 は完了しており、3 以降が AWS に関わるフェーズです。表の BFF、JWT、認可 API、IdP、前段、契約、publish の意味は [architecture/ の「用語」](../architecture/README.md#用語) にあります。

| # | 内容 | AWS の費用（月額、ドル） | 状態 |
|---|---|---|---|
| 1 | Compose によるローカルの最小構成 | 0 | 完了 |
| 1.5 | 認証と認可のローカル再現（IdP の Keycloak、前段の oauth2-proxy、BFF での JWT の検証、認可 API。[構成](../architecture/README.md#認証と認可)） | 0 | 完了 |
| 1.6 | OpenAPI を契約にしたリポジトリ分割（[契約とリポジトリの分割](../architecture/README.md#契約openapiとリポジトリの分割)）、クライアントの生成と配布（Reposilite / GitHub Packages。どちらも Maven リポジトリ）、Swagger UI（API の仕様をブラウザで読む画面） | 0 | 完了 |
| 2 | GitHub Actions（以下 Actions）の CI（単体テスト、型チェック、Compose でのスモークテスト、クライアントの publish） | 0 | 完了（CD は 3 以降） |
| 3 | IaC（Infrastructure as Code。AWS の構成をコードで書く）の土台、Actions が OIDC（OpenID Connect。ここでは GitHub が発行するトークンで AWS の一時的な認証情報を得る仕組み）で引き受ける IAM ロール（AWS を操作する権限をまとめたもの）、ECR（コンテナイメージの置き場）、Actions からのイメージ push | ほぼ 0（ECR の保存料だけで、月 1 ドル未満） | 未着手 |
| 4 | VPC（AWS 上の専用ネットワーク）、ALB（AWS のロードバランサー。入口になり、認証も行う）、ECS（Fargate）（コンテナをサーバーの管理なしで動かす）、RDS（マネージドの PostgreSQL）、Service Connect（ECS のサービス同士を名前でつなぐ）、デプロイ | 時間課金が始まる（「費用の見込み」の節） | 未着手 |
| 5 | ALB の認証（一般利用者の IdP の Keycloak と、社員の IdP の Okta。ホストごとのルール）、AWS 上での Keycloak の自前運用、ドメインの取得 | 約 25（Keycloak を自前で運用する分。常時稼働の場合）＋ ドメイン代（年 15 前後） | 未着手 |
| 6 | CodeArtifact（AWS の Maven / npm リポジトリ）による共通ライブラリの配布と依存のプロキシ、CodeBuild（AWS のビルド実行サービス）へのビルド移管 | 1〜2 程度 | 未着手 |

## フェーズ 3 以降に着手する前に決めること

フェーズ 3 に着手する前に決める 5 点は、2026-11-01 に作成者（ht-0328）が次の表のとおり決めました。それぞれの決定の内容と理由は、「詳しい節」の列の節にあります。

| # | 決めること | 決定 | 詳しい節 |
|---|---|---|---|
| 1 | IaC のツール | Terraform を使う | 「IaC」 |
| 2 | 運用の仕方 | 常時稼働にせず、学習するときだけ作って終わったら壊す（作っては壊す） | 「費用を抑える運用」 |
| 3 | ALB の認証に使うドメイン | 持っていないので、フェーズ 5 で Route 53（AWS の DNS とドメインのサービス）で取得する（年 15 ドル前後） | 「AWS での構成」 |
| 4 | AWS 上の Keycloak | ECS で自前運用する（選択肢 (a)） | 「IdP の用意」 |
| 5 | Nginx の配置 | パターン A（ALB の後ろに Nginx を置く）にする | 「Nginx の配置」 |

進め方も、同じ日に作成者が決めました。各フェーズのリソースは、まずマネジメントコンソール（AWS の Web 画面）で 1 回作って理解してから Terraform のコードに書き起こし、コンソールで作ったものは消します。残すのはコードだけです。先に作って見てから書くと、コードが何を作っているかを理解しやすいためです。

着手前に決めることのうち、まだ決めていないことは 2 つです（費用の合計の行の見直しは「費用の見込み」の節に書いた）。Okta を Developer アカウントの本物で試すかは、Okta を使うフェーズ 5 に着手する前に決めます。CodeBuild の呼び出し方は、フェーズ 6 で決めます（「GitHub Actions と CodeBuild の責務分担」の節）。

## AWS 化で決める構成

この節は、AWS に載せるときに決める構成を、関わるフェーズの順に並べます。IaC（フェーズ 3）、Nginx の配置（フェーズ 4）、ALB の認証（フェーズ 5）、GitHub Actions と CodeBuild の責務分担、CodeArtifact が担当すること（どちらもフェーズ 6）の順です。

### IaC

IaC のツールは、2026-11-01 に作成者が Terraform に決めました。AWS CDK（TypeScript で AWS の構成を書くツール）でも同じ構成を書けますが、Terraform は学習に使える資料が多く、一般の業務でも広く使われているので、Terraform にしました。Terraform のコードは、マネジメントコンソールで 1 回作って理解したものを書き起こします（「フェーズ 3 以降に着手する前に決めること」の節）。集約リポジトリ（このリポジトリ fullstack-lab）の `infra/` 配下に、環境ごとのディレクトリ（`envs/dev`）とモジュールを置く予定です。

### Nginx の配置

Nginx を AWS でどこに置くかは、2026-11-01 に作成者がパターン A に決めました。Nuxt は画面を描画するサーバーで、BFF とは別のコンテナです。次の表は、2 つのパターンを構成、長所、短所で比べます。

| | パターン A：ALB → Nginx → Nuxt / BFF | パターン B：ALB のパスルールで直接振り分け |
|---|---|---|
| 構成 | Nginx を ECS サービスとして置き、Service Connect で Nuxt と BFF へ転送する | `/bff/*` は BFF のターゲットグループ（ALB が転送する先のタスクをまとめたもの）、それ以外は Nuxt へ。Nginx は置かない |
| 長所 | ローカルと同じ設定ファイルを使える。ヘッダー操作やキャッシュを細かく制御できる | 中継が 1 つ減り、構成と費用が小さくなる |
| 短所 | 中継が 1 つ増える。Nginx 自体の運用が要る | ローカルと AWS でルーティングの定義が別々になる |

パターン A にしたのは、ローカルと AWS で同じ Nginx の設定ファイルを使えるためです（表の長所の 1 つ目）。業務環境（作成者が以前いた職場。このリポジトリはその構成を学習用に再現している。[用語](../architecture/README.md#用語)）での Nginx の位置は分かっていないので、この配置は学習用の仮定です（[仮定 1](../architecture/README.md#仮定)）。業務環境の構成が分かったら、そちらに合わせます。

### ALB の認証

フェーズ 5 では、ALB の認証アクションを前段（アプリより手前で認証とセッションを担う層。ローカルでは oauth2-proxy）にします。この節は、AWS での構成、IdP の用意、ローカルの代替と AWS との差分の順に示します。

#### AWS での構成

次の箇条書きは、ALB のリスナールールと、認証のあとに BFF へ渡るヘッダーを示します。

- **ALB の認証アクションは、HTTPS リスナー（ALB が HTTPS の通信を受け付ける設定）でしか使えません。そのためドメインと ACM（AWS の証明書発行サービス）の証明書が必須です。** ドメインは持っていないので、フェーズ 5 で Route 53 で取得します。
- HTTPS リスナーには、次のホストごとのルールを設定します（ホストで分けるのは学習用の仮定。[仮定 2](../architecture/README.md#仮定)）。`authenticate-oidc` は、OIDC に対応した IdP へログインさせる ALB の認証アクションです。realm は、Keycloak の中で利用者とログインの設定をまとめる単位です。
  - `mypage.<domain>`（一般利用者のマイページ）：`authenticate-oidc`（Keycloak の realm `customer`）
  - `admin.<domain>`（社員の管理画面）：`authenticate-oidc`（Okta）
  - `mypage.<domain>` の `/signup`、`/bff/signup`、`/_nuxt/*`：認証アクションなしで転送（会員登録の公開パス。ローカルの Nginx の `public-locations.conf` に相当。[仮定 13](../architecture/README.md#仮定)）
- 未認証の利用者は IdP（Identity Provider。ログインを受け付けてトークンを発行するサービス。ここでは Keycloak と Okta）へリダイレクトされます。認証のあと、ALB はセッション Cookie（`AWSELBAuthSessionCookie-*`）を発行し、次のヘッダーを付けて転送します。
  - `x-amzn-oidc-accesstoken`：IdP のアクセストークン（JWT）。**BFF が IdP の公開鍵で検証します**（ローカルと同じ。検証する対象をこのヘッダーにするのは学習用の仮定。[仮定 3](../architecture/README.md#仮定)）
  - `x-amzn-oidc-identity`：利用者の ID（`sub` クレーム）
  - `x-amzn-oidc-data`：ALB が ES256 で署名した JWT（利用者の情報）
- `/bff/*` のルールは `on-unauthenticated-request: deny` にして、リダイレクトではなく 401 を返させます（ローカルの Nginx と同じ動き）。

#### IdP の用意

一般利用者の IdP の Keycloak と、社員の IdP の Okta を、次のように用意します。

- Keycloak の置き場所には次の 2 通りがあり、2026-11-01 に作成者が (a) に決めました。
  - (a) ECS で自前運用し、DB は RDS を共有する（採用）
  - (b) 既存の Keycloak を使う想定にして、学習では Cognito（AWS の IdP サービス）などで代用する

  (a) にした理由は 2 つです。1 つ目は、運用を作っては壊すと決めたので（「費用を抑える運用」の節）、常時稼働との費用差がほとんど無いことです。2 つ目は、ローカルと同じ Keycloak の設定を使えるので、学んだ認証の仕組みがそのまま AWS で動くことです。
- Okta は [Okta Developer の無料アカウント](https://developer.okta.com/) で本物を試せます。本物を使うかは未決で、フェーズ 5 に着手する前に決めます。
- Okta を使う場合は、BFF が社員のトークンの発行元（issuer）として設定している Keycloak の realm `staff` を Okta に差し替えます。この設定は `web/bff/src/main/resources/application.yml` の `staff` にあり、値は環境変数 `STAFF_ISSUER_URI` などで渡すので、コードは変わりません。Okta の認可サーバーには、`groups` クレーム（社員のロールを載せる項目）を出す設定を足します。

#### ローカルの代替と AWS との差分

次の表は、ローカルで oauth2-proxy と Nginx が代わりに担っている動きを、AWS の ALB ではどうなるかと並べて示します。左がローカル、右が AWS です。

| 項目 | ローカル（Nginx + oauth2-proxy + Keycloak） | AWS（ALB + Keycloak / Okta） |
|---|---|---|
| ログイン画面とリダイレクト | 再現している（oauth2-proxy が担当） | ALB が担当 |
| セッション Cookie | `_fsl_customer` / `_fsl_staff`（oauth2-proxy が暗号化） | `AWSELBAuthSessionCookie-0,1...` |
| BFF への JWT | `x-amzn-oidc-accesstoken`（同じヘッダー名） | 同じ |
| `x-amzn-oidc-data`（ALB の署名） | 再現しない（空にする）。oauth2-proxy に ALB の署名を作る機能が無く、BFF も検証していないため | 付与される。追加で検証するなら BFF に実装する |
| 社員の IdP | Keycloak の realm `staff` が Okta の代わりをし、`groups` クレームを出す | Okta |
| URL | HTTP、`*.localhost`、IdP は 8180 番 | HTTPS、独自ドメイン |
| ブラウザ向けとコンテナ間の URL | 違う（`localhost:8180` と `keycloak:8080`）。そのため個別に設定が要る | どちらも IdP の公開 URL で同じ |
| トークンの更新 | oauth2-proxy が 4 分ごと（アクセストークンの有効期限 5 分より前に更新するため。`compose.yaml` の `OAUTH2_PROXY_COOKIE_REFRESH`）。Cookie は Nginx の `auth_request_set` でブラウザへ返す | ALB が更新する |
| ログアウト | `/oauth2/sign_out` が Cookie を消し、Keycloak のセッションも終了させる | ALB の Cookie を期限切れにし、IdP のログアウト URL へ遷移させる処理をアプリで実装する |
| Cookie のサイズ | 約 3.4KB。トークンが大きくなり Cookie が分割されると、Nginx 経由の更新で 2 本目が失われる | ALB は自分で分割を扱う |

アプリのコードに影響するのは、ログアウトの処理と、`x-amzn-oidc-data` を追加で検証する場合の BFF の 2 点です。

### GitHub Actions と CodeBuild の責務分担

この規模では、Actions だけでも CI/CD は完結します。CodeBuild には、**AWS の内側で実行する必要がある処理**だけを受け持たせます。CodeBuild を使うこと自体は目的にしません。次の表は、フェーズ 6 で CodeBuild を入れた後の、担当ごとに受け持つ処理と、そう分ける理由を示します。

| 担当 | 処理 | 理由 |
|---|---|---|
| Actions（GitHub ホストのランナー） | PR の検査（テスト、型チェック、スモークテスト）、ワークフロー全体の制御、dev 環境へのデプロイ前の承認（GitHub の Environments 機能。指定した人が承認するまでジョブを止める） | AWS の権限が要らず、無料枠で動く |
| Actions + OIDC | ECS へのデプロイ（タスク定義の更新、サービスの更新） | 長期のアクセスキーを持たずに、一時的な認証情報で AWS を操作できる |
| CodeBuild | デプロイするイメージのビルドと ECR への push、生成クライアントの CodeArtifact への publish（「CodeArtifact が担当すること」の 1）、VPC 内での処理（RDS に対するマイグレーションなど） | CodeArtifact や VPC 内のリソースに IAM ロールで直接アクセスできる。ビルドの記録が AWS 側に残る |

CodeBuild の呼び出し方は、次の 2 通りがあります。どちらにするかはフェーズ 6 で決めます。

- **Actions から `aws-actions/aws-codebuild-run-build` で起動する**：Actions が指揮役、CodeBuild が実行役という分担がはっきりします。
- **CodeBuild を Actions のセルフホストランナーにする**（`runs-on: codebuild-...`）：ワークフローは Actions の書き方のまま、ジョブの実行場所だけを AWS に移せます。

### CodeArtifact が担当すること

ローカルでは Reposilite、CI では GitHub Packages が担っている「生成クライアントの置き場」の役割を、AWS では CodeArtifact に置き換えます（今の配布の流れは [architecture/ の「成果物の配布」](../architecture/README.md#成果物の配布codeartifact-の代替)）。Gradle（Java と Kotlin のビルドツール）の設定は環境変数（`MAVEN_REPO_URL` など）で切り替わるので、コードは変わりません。担当させる役割は次の 3 つです。1 つ目は今の流れの置き換え、2 つ目と 3 つ目は AWS 化で新しく足すものです。

1. **生成クライアントの配布（実装済みの流れ）**：`api` / `authz` / `auth`（API、認可 API、認証 API の各リポジトリ。認証 API は一般利用者のアカウントを管理する API）が OpenAPI から生成した `api-client` / `authz-client` / `auth-client` を publish し、BFF がバージョンで依存します。publish は CodeBuild が VPC の中で IAM ロールを使って行います。取得する側（BFF のビルド）は、`aws codeartifact get-authorization-token` で得たトークンを `MAVEN_REPO_PASSWORD` に入れます。このトークンの有効期限は最長 12 時間です。
2. **依存パッケージのプロキシとキャッシュ**：Maven Central と npm を上流に登録し、Gradle と npm は CodeArtifact だけを参照するようにします。社外のレジストリが落ちても影響を受けにくくなり、取り込むパッケージも管理しやすくなります。
3. **社内共通ライブラリの配布**：いま `RequestIdFilter`（入口が付けた `X-Request-Id` をログに載せるフィルター）は、API・BFF・認可 API・認証 API に同じものを置いてあります。領域（独立したリポジトリで作る単位）の間でソースを直接参照しない決まり（[AGENTS.md](../../AGENTS.md)）があるためです。これを共通ライブラリに切り出し、CodeArtifact に publish して各サービスから使います。

GitHub Packages と CodeArtifact の違いは、認証（`GITHUB_TOKEN` と IAM）と、上流プロキシの有無です。学習では GitHub Packages で十分に流れを体験できるので、CodeArtifact は AWS 化の段階（フェーズ 6）で置き換えます。

## 費用の見込み（東京リージョン、dev 環境 1 つ、2026 年時点の概算）

次の表は、フェーズ 4 以降を 24 時間 365 日動かし続けた場合の月額の目安です。運用は作っては壊すと決めたので（「費用を抑える運用」の節）、実際の費用はこれより小さくなります。

| リソース | 規模 | 月額の目安（ドル） |
|---|---|---|
| ALB | 1 台、低トラフィック | 約 20〜25 |
| ECS Fargate | 7 タスク（Nginx、Nuxt、BFF、認証 API、認可 API、API、WireMock（カレンダー API のモック）。0.25 vCPU、0.5〜1 GB） | 約 88 |
| ECS Fargate（Keycloak） | 0.5 vCPU、1 GB。Keycloak を自前で運用すると決めたため含める | 約 25 |
| RDS for PostgreSQL | db.t4g.micro、シングル AZ、20 GB | 約 20〜25 |
| パブリック IPv4 アドレス | ALB とタスクで 9 個程度 | 約 30 |
| NAT Gateway（プライベートサブネットからインターネットへ出る経路） | **使わない**（「費用を抑える運用」の節） | 0（使うと +45 以上） |
| Route 53、ドメイン | ホストゾーン 1 つとドメイン 1 つ | 約 0.5 ＋ ドメイン代（年 15 ドル前後） |
| Okta | Developer アカウント | 0 |
| ECR、CloudWatch Logs（ログの保存）、CodeBuild、CodeArtifact | 小規模 | 合計で 5 以下 |
| **合計** | | **約 165〜225 / 月** |

合計の行は、表の各行を足した値（約 183.5〜198.5。ドメイン代を除き、「ECR、CloudWatch Logs、CodeBuild、CodeArtifact」の行を 0〜5 として足した）と合っていません。合計の行を見直すかどうかは、作成者がまだ決めていません（未決）。合計には、Keycloak を自前で運用する分（約 25）を含めています。自前で運用すると決めたためです（「フェーズ 3 以降に着手する前に決めること」の節）。

### 費用を抑える運用

「費用の見込み」の表の月額は、常時稼働の場合です。次の 4 つは、学習用の環境でその費用を抑える運用です。1 つ目の「作っては壊す」は、2026-11-01 に作成者が決めました。

- **学習するときだけ作り、終わったら壊します。** `terraform apply` で作り、学習し、`terraform destroy` で壊す順に進めます。時間あたり約 0.25 ドルなので、数時間の学習なら 1 回 1〜2 ドルです。マネジメントコンソールで作って試したリソースも、学習が終わったら消します。
- NAT Gateway を使わず、学習用としてパブリックサブネット（インターネットと直接やり取りできる区画）に Fargate タスクを置き、セキュリティグループ（通信の許可を決める AWS のファイアウォール）で ALB からの通信だけを許可します。本番ではプライベートサブネット（インターネットから直接は届かない区画）と NAT Gateway（または VPC エンドポイント）が普通の構成なので、その差分も学習項目として扱います。
- Fargate は Spot（AWS の空き容量を割安で使う方式）を使います。RDS は使わない間は停止します。停止しても、最長 7 日で自動的に再起動されます。
- AWS Budgets（予算を超えそうなときに通知するサービス）で、月 10 ドルなどの予算アラートを最初に設定します。

# AWS・CI/CD ロードマップ

ローカル構成が完成した後に、段階的に進める計画です。**AWS リソースの作成やデプロイは費用がかかるので、各フェーズを始める前に確認を取ります。** 金額はすべて概算です。実際の判断は [AWS Pricing Calculator](https://calculator.aws/) で確かめてください。

## フェーズ

| # | 内容 | AWS の費用 | 状態 |
|---|---|---|---|
| 1 | Docker Compose によるローカルの最小構成 | なし | 完了 |
| 1.5 | 認証と認可のローカル再現（Keycloak、oauth2-proxy、BFF での JWT 検証、認可 API） | なし | 完了 |
| 1.6 | OpenAPI を契約にしたリポジトリ分割、クライアントの生成と配布（Reposilite / GitHub Packages）、Swagger UI | なし | 完了 |
| 2 | GitHub Actions の CI（単体テスト、型チェック、Compose でのスモークテスト、クライアントの publish） | なし | 完了（CD は 3 以降） |
| 3 | IaC の土台、GitHub OIDC 用の IAM ロール、ECR、Actions からのイメージ push | ほぼ 0（ECR の保存料が月数十円） | 未着手 |
| 4 | VPC、ALB、ECS（Fargate）、RDS、Service Connect、デプロイ | 時間課金が始まる（下記） | 未着手 |
| 5 | ALB の認証（Keycloak と Okta、ホストごとのルール）、AWS 上での Keycloak の扱い | 0〜25（Keycloak を自前で運用するかどうか） | 未着手 |
| 6 | CodeArtifact（共通ライブラリと依存のプロキシ）、CodeBuild へのビルド移管 | 月 1〜2 ドル程度 | 未着手 |

## GitHub Actions と CodeBuild の責務分担

この規模では、GitHub Actions だけでも CI/CD は完結します。CodeBuild は「使うために使う」のではなく、**AWS の内側で実行する必要がある処理**を受け持たせます。

| 担当 | 処理 | 理由 |
|---|---|---|
| GitHub Actions（GitHub ホストのランナー） | PR の検査（テスト、型チェック、スモークテスト）、ワークフロー全体の制御、承認（Environments） | AWS の権限が要らず、無料枠で動く |
| GitHub Actions + OIDC | ECS へのデプロイ（タスク定義の更新、サービスの更新） | 長期のアクセスキーを持たずに、一時的な認証情報で AWS を操作できる |
| CodeBuild | 本番用イメージのビルドと ECR への push、VPC 内での処理（RDS に対するマイグレーションなど） | CodeArtifact や VPC 内のリソースに IAM ロールで直接アクセスできる。ビルドの記録が AWS 側に残る |

CodeBuild の呼び出し方は 2 通りあります。どちらにするかはフェーズ 6 で決めます。

- **Actions から `aws-actions/aws-codebuild-run-build` で起動する**：Actions が指揮役、CodeBuild が実行役という分担がはっきりします。
- **CodeBuild を Actions のセルフホストランナーにする**（`runs-on: codebuild-...`）：ワークフローは Actions の書き方のまま、ジョブの実行場所だけを AWS に移せます。

## CodeArtifact が担当すること

ローカルでは Reposilite、CI では GitHub Packages が担っている役割を、AWS では CodeArtifact に置き換えます。Gradle の設定は環境変数（`MAVEN_REPO_URL` など）で切り替わるので、コードは変わりません。

1. **生成クライアントの配布（実装済みの流れ）**：`api` / `authz` が OpenAPI から生成した `api-client` / `authz-client` を publish し、BFF がバージョンで依存します。publish は CodeBuild（VPC 内、IAM ロール）で行い、取得は `aws codeartifact get-authorization-token` で得たトークンを `MAVEN_REPO_PASSWORD` に入れます（有効期限は最長 12 時間）。
2. **依存パッケージのプロキシとキャッシュ**：Maven Central と npm を上流に登録し、Gradle と npm は CodeArtifact だけを参照するようにします。社外のレジストリが落ちても影響を受けにくくなり、取り込むパッケージも管理しやすくなります。
3. **社内共通ライブラリの配布**：いま `RequestIdFilter` は API・BFF・認可 API に同じものを置いてあります（意図的です）。これを共通ライブラリに切り出し、CodeArtifact に publish して各サービスから使います。

GitHub Packages と CodeArtifact の違いは、認証（`GITHUB_TOKEN` と IAM）と、上流プロキシの有無です。学習では GitHub Packages で十分に流れを体験できるので、CodeArtifact は AWS 化の段階（フェーズ 6）で置き換えます。

## ALB の認証

### AWS での構成

- ALB の HTTPS リスナーに、ホストごとのルールを設定します。**認証アクションは HTTPS リスナーでしか使えません。そのためドメインと ACM 証明書が必須です。**
  - `mypage.<domain>`：`authenticate-oidc`（Keycloak の realm `customer`）
  - `admin.<domain>`：`authenticate-oidc`（Okta）
  - `mypage.<domain>` の `/signup`、`/bff/signup`、`/_nuxt/*`：認証アクションなしで転送（会員登録の公開パス。ローカルの Nginx の `public-locations.conf` に相当）
- 未認証のユーザーは IdP へリダイレクトされます。認証後、ALB はセッション Cookie（`AWSELBAuthSessionCookie-*`）を発行し、次のヘッダーを付けて転送します。
  - `x-amzn-oidc-accesstoken`：IdP のアクセストークン（JWT）。**BFF が IdP の公開鍵で検証します**（ローカルと同じ）
  - `x-amzn-oidc-identity`：`sub`
  - `x-amzn-oidc-data`：ALB が ES256 で署名した JWT（ユーザー情報）
- `/bff/*` のルールは `on-unauthenticated-request: deny` にして、リダイレクトではなく 401 を返させます（ローカルの Nginx と同じ動き）。
- Keycloak の置き場所は 2 通りあります。どちらにするかはフェーズ 5 で決めます。
  - (a) ECS で自前運用し、DB は RDS を共有する
  - (b) 既存の Keycloak を使う想定にして、学習では Cognito などで代用する
- Okta は [Okta Developer の無料アカウント](https://developer.okta.com/) で本物を試せます。その場合は BFF の `staff` 発行元の設定を差し替えるだけで、コードは変わりません（`groups` クレームを出すように、Okta の認可サーバーでも設定します）。

### ローカルの代替と AWS との差分

| 項目 | ローカル（Nginx + oauth2-proxy + Keycloak） | AWS（ALB + Keycloak / Okta） |
|---|---|---|
| ログイン画面とリダイレクト | 再現している（oauth2-proxy が担当） | ALB が担当 |
| セッション Cookie | `_fsl_customer` / `_fsl_staff`（oauth2-proxy が暗号化） | `AWSELBAuthSessionCookie-0,1...` |
| BFF への JWT | `x-amzn-oidc-accesstoken`（同じヘッダー名） | 同じ |
| `x-amzn-oidc-data`（ALB の署名） | 再現しない（空にする） | 付与される。追加で検証するなら BFF に実装する |
| 社員の IdP | Keycloak の realm `staff` が Okta の代わりをし、`groups` クレームを出す | Okta |
| URL | HTTP、`*.localhost`、IdP は 8180 番 | HTTPS、独自ドメイン |
| ブラウザ向けとコンテナ間の URL | 違う（`localhost:8180` と `keycloak:8080`）。そのため個別に設定が要る | どちらも IdP の公開 URL で同じ |
| トークンの更新 | oauth2-proxy が 4 分ごと。Cookie は Nginx の `auth_request_set` でブラウザへ返す | ALB が更新する |
| ログアウト | `/oauth2/sign_out` が Cookie を消し、Keycloak のセッションも終了させる | ALB の Cookie を期限切れにし、IdP のログアウト URL へ遷移させる処理をアプリで実装する |
| Cookie のサイズ | 約 3.4KB。トークンが大きくなり Cookie が分割されると、Nginx 経由の更新で 2 本目が失われる | ALB は自分で分割を扱う |

## Nginx の配置

AWS 化の前に（フェーズ 4 の着手前に）決める点です。

| | パターン A：ALB → Nginx → Nuxt / BFF | パターン B：ALB のパスルールで直接振り分け |
|---|---|---|
| 構成 | Nginx を ECS サービスとして置き、Service Connect で Nuxt と BFF へ転送する | `/bff/*` は BFF のターゲットグループ、それ以外は Nuxt へ。Nginx は置かない |
| 長所 | ローカルと同じ設定ファイルを使える。ヘッダー操作やキャッシュを細かく制御できる | 中継が 1 つ減り、構成と費用が小さくなる |
| 短所 | 中継が 1 つ増える。Nginx 自体の運用が要る | ローカルと AWS でルーティングの定義が別々になる |

既定はパターン A です。業務環境の構成が分かったら、そちらに合わせます。

## IaC

**Terraform を仮定しています。** AWS CDK（TypeScript）でも同じ構成を書けます。フェーズ 3 に着手するときに選んでもらいます。`infra/` 配下に環境ごとのディレクトリ（`envs/dev`）とモジュールを置く予定です。

## 費用の見込み（東京リージョン、dev 環境 1 つ、2026 年時点の概算）

フェーズ 4 以降を 24 時間 365 日動かし続けた場合の目安です。

| リソース | 規模 | 月額の目安（USD） |
|---|---|---|
| ALB | 1 台、低トラフィック | 約 20〜25 |
| ECS Fargate | 7 タスク（Nginx、Nuxt、BFF、認証 API、認可 API、API、WireMock。0.25 vCPU、0.5〜1 GB） | 約 88 |
| ECS Fargate（Keycloak） | 0.5 vCPU、1 GB。自前で運用する場合だけ | 約 25 |
| RDS for PostgreSQL | db.t4g.micro、シングル AZ、20 GB | 約 20〜25 |
| パブリック IPv4 アドレス | ALB とタスクで 9 個程度 | 約 30 |
| NAT Gateway | **使わない**（後述） | 0（使うと +45 以上） |
| Route 53、ドメイン | ホストゾーン 1 つとドメイン 1 つ | 約 0.5 ＋ ドメイン代（年 15 前後） |
| Okta | Developer アカウント | 0 |
| ECR、CloudWatch Logs、CodeBuild、CodeArtifact | 小規模 | 合計で 5 以下 |
| **合計** | | **約 165〜225 / 月** |

### 費用を抑える運用（推奨）

- **学習するときだけ作り、終わったら壊します**（`terraform apply` → 学習 → `terraform destroy`）。時間あたり約 0.25 ドルなので、数時間の学習なら 1 回 1〜2 ドルです。
- NAT Gateway を使わず、学習用としてパブリックサブネットに Fargate タスクを置き、セキュリティグループで ALB からの通信だけを許可します。本番ではプライベートサブネットと NAT Gateway（または VPC エンドポイント）が普通の構成なので、その差分も学習項目として扱います。
- Fargate Spot を使い、RDS は使わない間は停止します（停止は最長 7 日で自動的に再起動されます）。
- AWS Budgets で、月 10 ドルなどの予算アラートを最初に設定します。

## フェーズ 3 以降に着手する前に確認したいこと

1. IaC は Terraform と CDK のどちらにするか
2. ALB の認証に使うドメインを持っているか（無い場合は Route 53 で取得すると年 15 ドル前後）
3. AWS 上の Keycloak を ECS で自前運用するか。Okta は Developer アカウントで本物を使うか
4. Nginx の配置をパターン A と B のどちらにするか
5. 常時稼働と「作っては壊す」運用のどちらにするか

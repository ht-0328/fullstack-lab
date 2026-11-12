# 生成クライアントの publish と取得

この文書は、契約（領域同士の API の取り決め。各領域の `openapi/*.yaml`。[用語](../../architecture/README.md#用語)）から生成したクライアントのライブラリを、どこへ publish（Maven リポジトリに登録すること。[用語](../../architecture/README.md#用語)）し、BFF（画面専用のサーバー側 API。[用語](../../architecture/README.md#用語)）がどう取得するかを記す。BFF は、API、認可 API、認証 API のソースを参照せず、publish されたクライアントにバージョンを指定して依存する（[仮定 10](../../architecture/README.md#仮定)）。成果物として配布する方針と理由は [ADR-0002](../../adr/ADR-0002-distribute-clients-as-artifacts.md) にある。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## 成果物

次の表は、publish する成果物を示す。グループはどれも `com.example.fullstacklab` で、バージョンは各リポジトリの `gradle.properties` の `version` である。

| 成果物 | publish するリポジトリ | 元の契約 |
|---|---|---|
| `api-client` | `api` | `api/openapi/api.yaml` |
| `authz-client` | `authz` | `authz/openapi/authz.yaml` |
| `auth-client` | `auth` | `auth/openapi/auth.yaml` |

BFF が使うバージョンは `web/bff/gradle.properties` にある（[API、認可 API、認証 API の呼び出し](../web/upstream-clients.md)）。

## 環境ごとの Maven リポジトリ

次の表は、環境ごとに、成果物を置く Maven リポジトリ（Java と Kotlin のライブラリを配布する形式の成果物リポジトリ）と、publish と取得の方法を示す。集約リポジトリの CI は、ローカルと同じ Reposilite を使う（[集約リポジトリの CI](ci.md)）。Reposilite と GitHub Packages は、AWS の CodeArtifact（AWS の成果物リポジトリのサービス）の代わりである。

| 環境 | Maven リポジトリ | publish | 取得 |
|---|---|---|---|
| ローカルと、集約リポジトリの CI | Reposilite（Compose の中で動く軽量な Maven リポジトリ。`http://localhost:8081/releases`） | 開発者か集約リポジトリの CI が `./scripts/publish-clients.sh` を実行する。トークンで認可する | 匿名で取得できる |
| 領域のリポジトリの CI | GitHub Packages（GitHub の成果物リポジトリ） | `api`、`authz`、`auth` の CI が、main に取り込まれたときに publish する。`packages: write` の権限で認可する | `packages: read` の権限が要る |

Gradle（Java と Kotlin のビルドツール）の設定は、どの環境でも同じである。次の表は、Maven リポジトリを切り替える環境変数を示す。

| 環境変数 | 中身 |
|---|---|
| `MAVEN_REPO_URL` | 取得する先の URL。無ければ `http://localhost:8081/releases` |
| `MAVEN_REPO_PUBLISH_URL` | publish する先の URL。無ければ `http://localhost:8081/releases` |
| `MAVEN_REPO_USER`、`MAVEN_REPO_PASSWORD` | 資格情報。取得では、無ければ匿名で取得する |

## 同じバージョンの扱い

同じバージョンの成果物は上書きしない。CodeArtifact と同じ運用にするためで、中身を変えたらバージョンを上げる（[契約のバージョンと変更の順序](contract-versioning.md)）。`scripts/publish-clients.sh` と CI の publish のジョブは、同じバージョンの成果物が既にあるかを先に確かめ、あれば publish せずに終わる。

## ローカルで publish するスクリプト

`scripts/publish-clients.sh` は、Reposilite を起動してから、`api`、`authz`、`auth` の順に `./gradlew :client:publish` を実行する。スクリプトは、JDK の公式のイメージの中で実行するので、ホストに JDK は要らない。資格情報は `.env` から読む。

## BFF のビルドでの取得

BFF のイメージのビルドは、Maven リポジトリからクライアントを取得する。資格情報は、Docker の build secret（ビルドの間だけ渡し、イメージに残さない値）で渡す。

## 失敗時の動作

次の表は、失敗の条件ごとの動作を示す。どれも利用者のリクエストには影響せず、影響を受けるのはビルドと取り込みである。

| 失敗の条件 | 検知の方法 | 動作 |
|---|---|---|
| 契約の `info.version` と `gradle.properties` の `version` がずれている | クライアントの Gradle タスク `checkSpecVersion` が、publish の前に 2 つを比べる | publish が失敗する |
| 同じバージョンを再び publish しようとした | スクリプトと CI のジョブが、成果物が既にあるかを確かめる | publish せずに成功で終わる |
| BFF のビルドが Maven リポジトリに届かない、または成果物が無い | 依存の解決が失敗する | ビルドが失敗する。ローカルでは、開発者が先に `./scripts/publish-clients.sh` を実行する |

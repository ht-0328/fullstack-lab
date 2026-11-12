# 契約からのコード生成

この文書は、契約（領域同士の API の取り決め。各領域の `openapi/*.yaml`。[用語](../../architecture/README.md#用語)）から何を生成し、どこに置き、どのコマンドで生成し直すかを記す。生成コードは git で管理し、手では直さない。その方針と理由は [ADR-0003](../../adr/ADR-0003-commit-generated-code.md) にある。

このフォルダの全体と、文書で使う語の意味は [領域をまたぐ仕組みの全体像](README.md) にある。

## 生成するもの

次の表は、契約ごとに、生成するものと置き場所を示す。提供側は契約を定義して公開する側、利用側はそれを呼ぶ側である（[用語](../../architecture/README.md#用語)）。DTO は、API でやり取りするデータの型を表すクラスである。

| 契約 | 生成するもの | 生成の道具 | 置き場所 |
|---|---|---|---|
| `api/openapi/api.yaml`、`authz/openapi/authz.yaml`、`auth/openapi/auth.yaml` | 提供側のコントローラーのインターフェースと DTO | OpenAPI Generator の `kotlin-spring`（`interfaceOnly`） | 各リポジトリの `src/generated` |
| 同じ 3 つの契約 | 利用側（BFF）が使うクライアント | OpenAPI Generator の `kotlin`（library は `jvm-spring-restclient`、Jackson 3） | 各リポジトリの `client/src/generated` |
| `web/openapi/bff.yaml` | BFF のコントローラーのインターフェースと DTO | OpenAPI Generator の `kotlin-spring`（`interfaceOnly`） | `web/bff/src/generated` |
| `web/openapi/bff.yaml` | 画面が使う型 | `openapi-typescript` | `web/frontend/app/types/bff.d.ts` |

提供側は、生成したインターフェースをコントローラーで実装する。実装が契約とずれると、コンパイルできずにビルドが失敗する。画面は型だけを生成し、BFF を呼ぶ処理は `openapi-fetch`（型付きの薄いクライアント）と手書きのコードで行う（[仮定 11](../../architecture/README.md#仮定)）。その理由は [ADR-0001](../../adr/ADR-0001-nuxt-generates-types-only.md) にある。

## 生成し直すコマンド

開発者は、契約を変えたら、集約リポジトリで `./scripts/generate.sh` を実行し、生成物を契約の変更と同じコミットに含める。次の一覧は、このスクリプトの動きを示す。

- スクリプトは、JDK と Node.js の公式のイメージの中で生成するので、ホストに JDK と Node.js は要らない
- スクリプトは、`api`、`authz`、`auth`、`web/bff` で `./gradlew generate` を、`web/frontend` で `npm run generate:bff` を実行する
- スクリプトは、`api`、`authz`、`auth` のうち、取得していないサブモジュールを飛ばす。`web` は取得済みであることが前提で、未取得ならスクリプトは失敗する
- スクリプトは、最後に、リポジトリごとの生成物の差分を一覧で出す

領域のリポジトリだけで作業するときは、そのリポジトリで `./gradlew generate`（画面は `web/frontend` で `npm run generate:bff`）を実行する。

## 生成コードの使い道

生成コードは、境界の内側へ広げない。契約が変わったときの影響を、変換する場所に閉じ込めるためである。API は業務モデルと DTO を変換し、BFF はクライアントの DTO と画面向けの DTO を変換する。

## 確認の方法

生成し忘れと手直しは、[生成コードの検査（`check-generated`）](check-generated.md) が見つける。

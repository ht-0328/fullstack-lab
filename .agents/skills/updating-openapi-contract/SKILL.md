---
name: updating-openapi-contract
description: >-
  fullstack-lab の契約（web/openapi/bff.yaml、api/openapi/api.yaml、authz/openapi/authz.yaml、auth/openapi/auth.yaml）を変更するときの手順。
  提供側（仕様・バージョン・生成・実装・publish）と利用側（クライアントのバージョン追従）の両方を扱う。
  エンドポイントや DTO の追加・変更・削除、BFF と画面の間の項目変更を頼まれたときに使う。
---

# 契約（OpenAPI）を変える

## 1. 原則

- **仕様が正。** 生成コード（各リポジトリの `src/generated`、`client/src/generated`、`frontend/app/types/bff.d.ts`）は git で管理しますが、手で直しません。仕様を直して生成し直し、生成物も同じコミットに含めます。生成し忘れや手直しは Docker の test / typecheck ステージ（`check-generated`）が落とします（[ADR-0003](../../../docs/adr/ADR-0003-commit-generated-code.md)）。
- **同じバージョンは上書きしない。** 契約を変えたら必ずバージョンを上げます。publish 済みの成果物は残るので、提供側と利用側を同時にデプロイする必要はありません。
- **互換性を宣言する。** 項目の追加は互換（パッチまたはマイナー）。必須項目の追加、項目の削除、型や意味の変更は非互換（メジャー）。

## 2. 提供側の手順（api / authz / auth）

1. `openapi/<name>.yaml` を変え、`info.version` を上げる。
2. `gradle.properties` の `version` を同じ値にする（違うと `:client:publish` が失敗します）。
3. 生成し直す: `./gradlew generate`（ホストに JDK が無ければ集約リポジトリで `./scripts/generate.sh`）。`src/generated` と `client/src/generated` の差分をコミットに含める。
4. 実装を合わせる: `docker build --target test .`（コントローラーは生成したインターフェースを実装しているので、変更点はコンパイルエラーとして現れます。生成し忘れていれば `check-generated` ステージで止まります）。
5. Karate を更新して実行: `docker compose -f compose.test.yaml build && docker compose -f compose.test.yaml run --rm karate`。
6. PR を出す（`pr-and-commit`）。本文の「実装内容」に互換性と、影響する呼び出し側（BFF）を書く。
7. main にマージされると CI が GitHub Packages へ publish します。ローカルでは集約リポジトリで `./scripts/publish-clients.sh`。

## 3. 利用側の手順（web/bff）

1. `bff/gradle.properties` の `apiClientVersion` / `authzClientVersion` / `authClientVersion` を上げる。
2. 実装を合わせる: `docker build --target test --network host -f bff/Dockerfile .`（ローカルは publish 済みが前提）。
3. BFF の契約（`openapi/bff.yaml`）にも影響するなら、`./scripts/generate.sh`（各ディレクトリでは `bff` で `./gradlew generate`、`frontend` で `npm run generate:bff`）で生成し直し、画面側も同時に合わせる: `docker build --target typecheck -f frontend/Dockerfile .`。
4. PR を出す。本文に「追従した契約のバージョン」を書く。

## 4. 画面と BFF の契約（web/openapi/bff.yaml）

同じリポジトリなので 1 つの PR で両側を変えます。BFF の `BffController` は生成した `MeApi` / `TasksApi` を実装し、画面は `useBff()`（`openapi-fetch`）経由で呼びます。型の変更は `npm run typecheck` で画面側のエラーとして現れます。生成し直した `bff/src/generated` と `frontend/app/types/bff.d.ts` も同じ PR に含めます。

## 5. 確認

集約リポジトリで `./scripts/publish-clients.sh && docker compose up -d --build --wait && ./scripts/smoke-test.sh` が通ること。Swagger UI（`/swagger/`）で仕様が意図どおりに見えること。

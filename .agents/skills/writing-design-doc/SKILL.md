---
name: writing-design-doc
description: >-
  fullstack-lab の機能追加・変更について、実装の前に設計書（docs/design/NNNN-<slug>.md）を書く、または既存の設計書を更新する。
  「〜の設計書を書いて」「〜を追加したい（設計から）」と頼まれたとき、契約（OpenAPI）や複数リポジトリに影響する変更を始める前に使う。
  設計書が既にあり、その実装だけを頼まれたときは implementing-from-design を使う。
---

# 設計書を書く

## 1. 目的

実装者（人でも AI でも）が追加の質問なしに着手でき、レビュアーが採用案の妥当性を判断できる設計書を作ります。

## 2. 手順

1. [docs/README.md](../../../docs/README.md)（文書の種類と決まり）と [docs/design/TEMPLATE.md](../../../docs/design/TEMPLATE.md) を読み、テンプレートを複製して始めます。書き方に迷ったら直近の設計書（[0005](../../../docs/design/0005-auth-api-and-signup.md)）を例にします。
2. 既存の設計書（[docs/design/README.md](../../../docs/design/README.md)）、[docs/architecture/](../../../docs/architecture/README.md)、関係する契約（`web/openapi/bff.yaml`、`api/openapi/api.yaml`、`authz/openapi/authz.yaml`、`auth/openapi/auth.yaml`）を読み、矛盾や重複を確かめます。
3. テンプレートの節をすべて埋めます。該当しない観点は行ごと削り、**なぜ該当しないかを 1 行書きます**（空欄のまま残しません）。
4. 次の節を必ず入れます。この構成に固有の判断がここに集まるためです。
   - **影響するリポジトリ**: `web` / `api` / `authz` / `auth` / 集約のどれを変えるか。変えない理由も書く
   - **契約の変更**: 変える `openapi/*.yaml` と、互換か非互換か（必須項目の追加・削除・型変更は非互換）。非互換ならバージョンの上げ方と、呼び出し側の追従の順序
   - **認可**: 新しい操作（`task:xxx`）が増えるなら、利用者の種別ごとの可否と、認可 API の設定（`authz/src/main/resources/application.yml`）の差分
   - **テスト**: どの層で何を確かめるか（単体 / Karate / Playwright / スモーク）
   - **実装の段取り**: PR の分割と順序、各段を終えてよい条件、手で行う操作（AWS の画面操作など）。承認時にレビューし、実装はこの順で進める
5. 未決事項は「未決事項」の表に、判断に必要な情報と担当者を付けて書き、**ユーザーに質問として提示します**。推測で決めません。
6. `docs/design/README.md` の索引に 1 行追加します。状態は「提案」から始めます。
7. 書き終えたら [writing-docs](../writing-docs/SKILL.md) の 2〜4 の手順で `doc-review` エージェントに評価させ、指摘を直して合格させてから PR を出します。結果は `docs/review/` に残します。

## 3. 制約

- 業務環境の事実と、学習用の仮定を区別します。不確かな点は「仮定」と明記します（[docs/architecture/ の仮定](../../../docs/architecture/README.md#仮定)）。
- 設計書にコードは書きません。契約の差分は OpenAPI の抜粋で示します。
- 既存の設計書と矛盾するときは、どちらが正かを勝手に決めず、矛盾点として報告します。
- 他の設計書にも従わせたい方針が含まれるなら、ADR も書きます（[docs/adr/TEMPLATE.md](../../../docs/adr/TEMPLATE.md)、索引は [docs/adr/README.md](../../../docs/adr/README.md)）。使い分けは [docs/README.md](../../../docs/README.md#設計書と-adr-の使い分け)。

## 4. 出力

`docs/design/NNNN-<slug>.md`（番号は索引の次の番号）。先頭の表に 発信日・作成者・想定読者・読んだあとできること を入れます。

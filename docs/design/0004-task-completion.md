# 0004 タスクの完了の設計書

> **状態: 実装済み。** 2026-11-01 に未決事項 2 件を解消して承認し、同日に実装した。設計書駆動の流れを試す題材として用意した。

| 項目 | 内容 |
|---|---|
| 発信日 | 2026-10-28 |
| 作成者 | ht-0328（Claude Code で作成） |
| 機密区分 | 公開可 |
| 保守責任者 | ht-0328 |
| 最終確認日 | 2026-11-01 |
| 実装 PR | fullstack-lab-api#1、fullstack-lab-authz#1、fullstack-lab-web#1、fullstack-lab#6（設計書は fullstack-lab#5） |
| 想定読者（宛先） | この機能を実装する開発者（人と AI）、レビュアー |
| この文書を読んだあと読者ができること | 契約の変更内容と順序、認可の追加、画面の変更を把握し、追加の質問なしに実装に着手できる |

## 解決する課題

タスクを「完了」にできず、一覧が増える一方で、片付いたものを見分けられない。

| 項目 | 内容 |
|---|---|
| 対象 | タスクの完了状態と、画面での表示・操作 |
| 発生規模 | 学習用。件数は数百件以内 |
| 読者への影響 | 一覧で未完了と完了を見分けられる。完了の操作で、契約変更・認可の追加・画面の変更を一通り体験できる |
| 成功条件 | 本人（または `task-admin`）が完了にでき、一覧と詳細に反映される。他人のタスクは完了にできない。Karate・Playwright・スモークテストが通る |

## 制約と前提

| 区分 | 内容 | 根拠 |
|---|---|---|
| 制約 | 契約の変更は後方互換にし、API → BFF の順で取り込む | [0003](0003-contracts-and-repositories.md)、`updating-openapi-contract` |
| 制約 | 新しい操作は認可 API で判定する（画面の出し分けは守りではない） | [0002](0002-authentication-authorization.md) |
| 前提 | 完了の取り消しは対象外 | 題材を小さくするため |
| 前提 | 一覧の絞り込み（完了したタスクを隠す）は対象外。一覧は全件を出し、完了の印で見分ける | 題材を小さくするため。一覧の契約を変えずに済む |

## 採用案

タスクに完了日時を持たせ、完了の操作を独立したエンドポイントにする。

| 要素 | 採用内容 | 責務 |
|---|---|---|
| DB | `tasks.completed_at timestamptz null`（V3） | null なら未完了 |
| API | `POST /api/tasks/{id}/completion` → 200 `Task`。`Task` に `completedAt`（nullable）を追加。既に完了しているタスクには何もせず、現状の `Task` を 200 で返す（冪等。`completedAt` は最初の値のまま） | 完了日時を記録する |
| 認可 API | 操作 `task:complete`。一般利用者は所有者のみ、社員は `task-admin` のみ | 可否の判定 |
| BFF | `POST /bff/tasks/{id}/complete` → 200 `TaskDetailView`。所有者を知るために先に API からタスクを取得し（無ければ 404）、認可 API に `task:complete` を問い合わせ、許可されたときだけ API の完了を呼ぶ。`TaskSummaryView` / `TaskDetailView` に `completedAt` を追加。`Capabilities` に `canCompleteTask` は持たせず、詳細に `canComplete` を返す（完了済みなら認可 API に聞かず false） | 取得 → 認可 → API → 画面向け DTO |
| 画面 | 詳細に「完了にする」ボタン（`canComplete` のとき）と完了日時。一覧は全件を出し、完了したタスクに完了の印を付ける（既定で隠さない） | 操作と表示 |

### 影響するリポジトリ

| リポジトリ | 変更 |
|---|---|
| `api` | V3 マイグレーション、`Task` / `TaskRepository` / `TaskController`、`openapi/api.yaml` 1.1.0、Karate |
| `authz` | `application.yml` に `task:complete`、`PolicyTest`、Karate。契約は変えない（操作名は自由文字列） |
| `web` | `bff/gradle.properties` の `apiClientVersion` を 1.1.0 に、`openapi/bff.yaml` 1.2.0、`TaskViewService`、ページ 2 つ、Playwright |
| 集約 | スモークテストに完了の経路を追加、サブモジュールの参照更新 |

### 契約の変更

| 契約 | 版 | 変更 | 互換性 |
|---|---|---|---|
| `api/openapi/api.yaml` | 1.0.0 → 1.1.0 | `Task.completedAt`（任意、nullable）を追加。`POST /api/tasks/{id}/completion` を追加 | 互換（追加のみ） |
| `web/openapi/bff.yaml` | 1.1.0 → 1.2.0 | `TaskSummaryView.completedAt`、`TaskDetailView.completedAt` と `canComplete`、`POST /bff/tasks/{id}/complete` | 互換（追加のみ） |

### 認可

| 操作 | 一般利用者 | 社員 `task-viewer` | 社員 `task-admin` |
|---|---|---|---|
| `task:complete` | 自分のタスクだけ | 不可 | 可 |

認可 API の契約（`authz/openapi/authz.yaml`）は変えない。操作名は自由文字列で、一般利用者の「自分のタスクだけ」は既存の `task:read` と同じく `resource.ownerId` と `subject` の一致で判定する。設定（`authz/src/main/resources/application.yml`）の差分:

```yaml
authz:
  staff-role-permissions:
    task-viewer: [ "task:list", "task:read" ]                    # 変えない
    task-admin:  [ "task:list", "task:read", "task:create", "task:complete" ]
  customer-actions: [ "task:list", "task:read", "task:create", "task:complete", "account:change-password" ]
```

### テスト

| 層 | 確かめること |
|---|---|
| `authz` の `PolicyTest`、Karate | 上の表のとおりに判定する |
| `api` の Karate | 完了で `completedAt` が入る。既に完了しているタスクへの再実行は 200 で `completedAt` が変わらない。存在しない ID は 404 |
| `web/bff` の `TaskViewServiceTest` | 拒否なら API を呼ばない。`canComplete` が認可結果と一致する |
| Playwright | 本人が完了にでき、一覧に印が出る。完了済みにはボタンが出ない。`task-viewer` にはボタンが出ず、直接呼んでも 403。`task-admin` は他人のタスクも完了にできる |
| スモークテスト | 完了の経路（Nginx → BFF → 認可 API → API → DB） |

## 比較した代替案とトレードオフ

| 案 | 利点 | 欠点 | 採否の理由 |
|---|---|---|---|
| 完了日時を持ち、専用エンドポイントで完了にする（採用） | 操作の意味が契約に現れ、認可の単位と一致する。いつ完了したかが残る | エンドポイントが増える | 操作ごとの認可を学ぶ題材に合う |
| `PATCH /api/tasks/{id}` で任意の項目を更新する | 将来の更新全般に使える | 「何を変えたか」が本文次第になり、認可の判定が複雑になる | 不採用。更新全般は別の設計で扱う |
| `done` の真偽値だけ持つ | 単純 | 完了日時が残らない | 不採用。列を増やすコストは小さい |
| 既に完了しているタスクへの完了操作を 409 で知らせる | 二重実行に利用者が気づける | 再送や二重クリックが失敗に見え、画面と呼び出し側の扱いが増える | 不採用。完了は状態を目標値に揃える操作で、何度呼んでも同じ結果になる（冪等）ほうが扱いやすい |
| 一覧で完了したタスクを既定で隠し、切り替えで表示する | 一般的な ToDo アプリの振る舞い | API と BFF の一覧に絞り込みの query parameter、画面に切り替えが増える | 不採用。題材を小さくするため。必要になったら別の設計で扱う |

## 失敗時の動作

| 失敗条件 | 検知方法 | システムの動作 | 利用者への影響 |
|---|---|---|---|
| 権限のない利用者が完了を呼ぶ | 認可 API が拒否 | BFF は 403。完了の API（`POST /api/tasks/{id}/completion`）は呼ばない（所有者を知るための `GET` は認可の前に呼ぶ） | 「この操作は許可されていません」 |
| 存在しないタスクを完了にする | API の `GET` が 404 | BFF も 404 | 「タスクが見つかりません」 |
| 既に完了しているタスクを完了にする | API が `completed_at` の有無を見る | 何もせず、現状の `Task` を 200 で返す（冪等）。`completedAt` は最初の値のまま | 成功と同じ表示。二重クリックや再送でエラーにならない |
| 認可 API が応答しない | BFF の `AuthzClient` | 503（既存どおり fail-closed） | 完了できない |

## 技術観点の確認

該当しない観点は行ごと削り、該当しない理由を 1 行書いている（テンプレートの O-07）。

### セキュリティと権限

| 観点 | 内容 |
|---|---|
| 認可 | `task:complete` を認可 API に追加。画面のボタンの有無は守りではなく、BFF が必ず判定する |

認証、秘密情報、通信の暗号化、監査ログは既存の仕組みのまま（[0001](0001-task-management.md)）。

### データ

| 観点 | 内容 |
|---|---|
| 移行 | V3 で列を追加するだけ。既存の行は null（未完了）になり、切り戻しても壊れない |

扱う個人情報、保持期間、容量は変わらない。

### 性能と可用性、可観測性

| 観点 | 内容 |
|---|---|
| 性能 | 詳細の表示で認可 API を 2 回呼ぶ（`task:read` と、`canComplete` のための `task:complete`）。学習用の規模（数百件、少人数）では問題にしない |

可用性と可観測性は変わらない。

### 展開と後始末

| 観点 | 内容 |
|---|---|
| 展開手順 | `api` を先に取り込み 1.1.0 を publish → `web` が追従 → 集約の参照更新。古い BFF は `completedAt` を無視するので、順に展開できる |
| 切り戻し | `web` を戻す。API の 1.1.0 は互換なので残してよい |

## 未決事項

なし。2026-11-01 に次の 2 点を利用者に確認し、本文に反映した。

- 既に完了しているタスクへの完了操作 → 冪等にし、何もせず 200 で現状を返す（409 にしない）
- 一覧で完了したタスクを既定で隠すか → 隠さない。全件を出し、完了の印で見分ける（絞り込みは対象外）

## 課題・申し送り事項

- 完了の取り消しと、一覧の絞り込み（完了を隠す）は含めない。必要になったら別の設計で扱う
- 契約の版は、`api/openapi/api.yaml` が 1.0.0 → 1.1.0、`web/openapi/bff.yaml` が 1.1.0 → 1.2.0（[0005](0005-auth-api-and-signup.md) で 1.1.0 になっているため。起案時の「1.0.0 → 1.1.0」を訂正した）

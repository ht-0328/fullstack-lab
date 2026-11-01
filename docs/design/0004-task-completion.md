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

利用者（アプリを使う人。一般利用者と社員の 2 種類。[用語](../architecture/README.md#用語)）はタスクを登録できるが、片付いたタスクを「完了」にする手段が無い。一覧は増える一方で、まだやることと済んだことを見分けられない。この設計書は、タスクを完了にする操作を画面と API に足し、一覧と詳細で完了を見分けられるようにする。契約の変更、認可の追加、画面の変更を一通り含むので、設計書から実装する流れを試す最初の題材にした。

次の表は、この変更の対象と規模、何ができれば完了かをまとめる。

| 項目 | 内容 |
|---|---|
| 対象 | タスクの完了状態と、画面での表示・操作 |
| 発生規模 | リポジトリ 4 つ（`api`、`authz`、`web` と、このリポジトリ fullstack-lab である集約リポジトリ）。契約 2 つの互換変更。データは学習用で数百件以内 |
| 読者への影響 | 今はタスクを完了にできず、済んだタスクが一覧に残り続ける。この変更は、契約変更・認可の追加・画面の変更を一通り含む題材でもある |
| 成功条件 | タスクの所有者（一般利用者）か、社員のうちロール `task-admin` を持つ人が完了にでき、一覧と詳細に反映される。一般利用者は他人のタスクを完了にできない。Karate（API のテスト）・Playwright（画面のテスト）・スモークテスト（入口の Nginx から DB まで通す確認）が通る |

## 制約と前提

次の表は、この設計が従う制約と、前提にしていること、仮定を分けて示す。

| 区分 | 内容 | 根拠 |
|---|---|---|
| 制約 | 契約（領域同士の API の取り決め。各領域の `openapi/*.yaml`。[用語](../architecture/README.md#用語)）の変更は後方互換にし、API → BFF（画面専用のサーバー側 API）の順で取り込む | [0003 契約とリポジトリ分割、クライアントの配布](0003-contracts-and-repositories.md)。取り込みの順序は契約を変える手順（スキル `updating-openapi-contract`）に従う |
| 制約 | 新しい操作は認可 API（主体・操作・対象を渡して可否を返す API）で判定する。画面の出し分けは守りではない | [0002 認証と認可](0002-authentication-authorization.md) |
| 前提 | 完了の取り消しは対象外 | 題材を小さくするため |
| 前提 | 一覧の絞り込み（完了したタスクを隠す）は対象外。一覧は全件を出し、状態の列の「完了」で見分ける | 題材を小さくするため。一覧の契約を変えずに済む |
| 仮定 | 一般利用者は自分のタスクだけ、社員はロール `task-admin` を持つ人だけが完了にできる | [構成の仮定 5・6](../architecture/README.md#仮定) |

## 採用案

タスクに完了日時を持たせ、完了の操作を独立したエンドポイントにする。次の表は、採用案を要素ごとに分け、採用内容と責務を示す。

| 要素 | 採用内容 | 責務 |
|---|---|---|
| DB | `tasks.completed_at timestamptz null`。API の起動時に Flyway（DB のマイグレーションツール）がマイグレーション V3 として列を足す | null なら未完了 |
| API | `POST /api/tasks/{id}/completion` を足し、200 で `Task` を返す。`Task` に `completedAt`（nullable）を足す。既に完了しているタスクには何もせず、現状の `Task` を 200 で返す（冪等。何回呼んでも結果が同じになる。`completedAt` は最初の値のまま） | 完了日時を記録する |
| 認可 API | 操作 `task:complete` を足す。一般利用者は所有者だけ、社員はロール `task-admin` を持つ人だけを許可する | 完了してよいかを判定する |
| BFF | `POST /bff/tasks/{id}/complete` を足し、200 で `TaskDetailView` を返す。所有者を知るために先に API からタスクを取得し（無ければ 404）、認可 API に `task:complete` を問い合わせ、許可されたときだけ API の完了を呼ぶ。`TaskSummaryView`（一覧の 1 行）と `TaskDetailView`（詳細）に `completedAt` を足す。利用者単位の `Capabilities`（画面が操作の可否を知るための既存の DTO）には `canCompleteTask` を持たせない。完了できるかはタスクごと（所有者か、完了済みか）に決まるので、詳細 `TaskDetailView` に `canComplete` を返す（完了済みなら認可 API に聞かず false にする） | タスクの取得、認可の問い合わせ、API の呼び出し、画面向けの DTO（画面が受け取る形のデータ）への変換を順に行う |
| 画面 | 詳細の「状態」の行に「完了（完了日時）」か「未完了」を出し、`canComplete` が true のときだけ「完了にする」ボタンを出す。一覧は全件を出し（完了したタスクを既定で隠さない）、状態の列に「完了」か「未完了」を出す | 操作と表示 |

### 影響するリポジトリ

次の表は、リポジトリごとに変更の内容を示す。

| リポジトリ | 変更 |
|---|---|
| `api` | V3 マイグレーション、`Task` / `TaskRepository` / `TaskController`、`openapi/api.yaml` 1.1.0、Karate |
| `authz` | `application.yml` に `task:complete`、`PolicyTest`、Karate。契約は変えない（操作名は自由文字列） |
| `auth` | なし。アカウントの操作は変わらない |
| `web` | `bff/gradle.properties` の `apiClientVersion` を 1.1.0 に、`openapi/bff.yaml` 1.2.0、`TaskViewService`、一覧と詳細のページ（`frontend/app/pages/index.vue`、`frontend/app/pages/tasks/[id].vue`）、Playwright |
| 集約 | スモークテスト（`scripts/smoke-test.sh`）に完了の経路を追加、サブモジュールの参照更新 |

### 契約の変更

次の表は、変える契約と版、変更の内容、互換性を示す。どちらも追加だけなので互換で、API → BFF の順に取り込む。

| 契約 | 版 | 変更 | 互換性 |
|---|---|---|---|
| `api/openapi/api.yaml` | 1.0.0 → 1.1.0 | `Task.completedAt`（任意、nullable）を追加。`POST /api/tasks/{id}/completion` を追加 | 互換（追加のみ） |
| `web/openapi/bff.yaml` | 1.1.0 → 1.2.0 | `TaskSummaryView.completedAt`、`TaskDetailView.completedAt` と `canComplete`、`POST /bff/tasks/{id}/complete` | 互換（追加のみ） |

`web/openapi/bff.yaml` は [0005 認証 API と会員登録](0005-auth-api-and-signup.md) で 1.1.0 になっているため、この変更で 1.2.0 にする。

次の抜粋は、2 つの契約に足したパスと項目だけを示す。他の項目と、応答の詳しい定義は省いた。

```yaml
# api/openapi/api.yaml（1.1.0）
paths:
  /api/tasks/{id}/completion:
    post:            # 200: Task（既に完了なら現状を返す） / 404
components:
  schemas:
    Task:
      properties:
        completedAt: { type: string, format: date-time, nullable: true }
```

```yaml
# web/openapi/bff.yaml（1.2.0）
paths:
  /bff/tasks/{id}/complete:
    post:            # 200: TaskDetailView / 401 / 403 / 404
components:
  schemas:
    TaskSummaryView:
      properties:
        completedAt: { type: string, format: date-time, nullable: true }
    TaskDetailView:
      required: [ ..., canComplete ]
      properties:
        completedAt: { type: string, format: date-time, nullable: true }
        canComplete: { type: boolean }
```

### 認可

次の表は、利用者の種別ごとに `task:complete` の可否を示す。社員はロールで、一般利用者は所有者かどうかで決まる。

| 操作 | 一般利用者 | 社員 `task-viewer` | 社員 `task-admin` |
|---|---|---|---|
| `task:complete` | 自分のタスクだけ | 不可 | 可 |

認可 API の契約（`authz/openapi/authz.yaml`）は変えない。操作名は自由文字列なので、契約を変えずに操作を足せる。一般利用者の「自分のタスクだけ」は、既存の `task:read` と同じく `resource.ownerId` と `subject` の一致で判定する。

次の抜粋は、設定（`authz/src/main/resources/application.yml`）の差分を示す。`task-admin` と `customer-actions` に `task:complete` を足した。

```yaml
authz:
  staff-role-permissions:
    task-viewer: [ "task:list", "task:read" ]                    # 変えない
    task-admin:  [ "task:list", "task:read", "task:create", "task:complete" ]
  customer-actions: [ "task:list", "task:read", "task:create", "task:complete", "account:change-password" ]
```

### テスト

次の表は、層ごとに何を確かめるかを示す。認可の守りは画面のボタンの有無ではなく、直接呼んで 403 になることで確かめる。

| 層 | 確かめること |
|---|---|
| `authz` の `PolicyTest`、Karate | 「認可」の表のとおりに判定する |
| `api` の Karate | 完了で `completedAt` が入る。既に完了しているタスクへの再実行は 200 で `completedAt` が変わらない。存在しない ID は 404 |
| `web/bff` の `TaskViewServiceTest` | 拒否なら API を呼ばない。`canComplete` が認可結果と一致する |
| Playwright | タスクの所有者が完了にでき、一覧の状態の列に「完了」が出る。完了済みのタスクには「完了にする」ボタンが出ない。`task-viewer` の社員にはボタンが出ず、直接呼んでも 403 になる。`task-admin` の社員は他人のタスクも完了にできる |
| スモークテスト | 入口（Nginx）から BFF、認可 API、API を経て DB まで通す。所有者は 200、他の一般利用者と `task-viewer` の社員は 403、存在しない ID は 404 になる。2 回目の完了でも完了日時は変わらず、`task-admin` の社員は他人のタスクも完了にできる |

## 比較した代替案とトレードオフ

次の表は、検討した案を採用案も含めて並べ、採否の理由を示す。

| 案 | 利点 | 欠点 | 採否の理由 |
|---|---|---|---|
| 完了日時を持ち、専用エンドポイントで完了にする（採用） | 操作の意味が契約に現れ、認可の単位と一致する。いつ完了したかが残る | エンドポイントが増える | 操作ごとの認可を学ぶ題材に合う |
| `PATCH /api/tasks/{id}` で任意の項目を更新する | 将来の更新全般に使える | 「何を変えたか」が本文次第になり、認可の判定が複雑になる | 不採用。更新全般は別の設計で扱う |
| `done` の真偽値だけ持つ | 列が 1 つ増えるだけで、API と画面の扱いが単純 | 完了日時が残らない | 不採用。列を増やすコストは小さい |
| 既に完了しているタスクへの完了操作を 409 で知らせる | 二重実行に利用者が気づける | 再送や二重クリックが失敗に見え、画面と呼び出し側の扱いが増える | 不採用。完了は状態を目標値に揃える操作で、何度呼んでも同じ結果になる（冪等）ほうが扱いやすい |
| 一覧で完了したタスクを既定で隠し、切り替えで表示する | 一般的な ToDo アプリの振る舞い | API と BFF の一覧に絞り込みの query parameter、画面に切り替えが増える | 不採用。題材を小さくするため。必要になったら別の設計で扱う |

## 失敗時の動作

次の表は、失敗の条件ごとに、どう検知し、システムがどう動き、利用者にどう見えるかを示す。

| 失敗条件 | 検知方法 | システムの動作 | 利用者への影響 |
|---|---|---|---|
| 権限のない利用者が完了を呼ぶ | 認可 API が拒否を返す | BFF は 403 を返す。完了の API（`POST /api/tasks/{id}/completion`）は呼ばない（所有者を知るための `GET` は認可の前に呼ぶ） | 「この操作は許可されていません」と表示される |
| 存在しないタスクを完了にする | API の `GET` が 404 を返す | BFF も 404 を返す | 「タスクが見つかりません」 |
| 既に完了しているタスクを完了にする | API が `completed_at` の有無を見る | 何もせず、現状の `Task` を 200 で返す（冪等）。`completedAt` は最初の値のまま | 成功と同じ表示。二重クリックや再送でエラーにならない |
| 認可 API が応答しない | BFF の `AuthzClient` の呼び出しが失敗する | BFF は 503 を返し、完了の API は呼ばない（判定できないときは拒否する fail-closed。既存どおり） | 完了できない。詳細画面のボタンの下に、BFF が返したエラーの詳細（`authorization service unavailable`）が表示される |

## 技術観点の確認

該当しない観点は行ごと削り、該当しない理由を 1 行書いている（[docs の決まり](../README.md#形式の決まり)）。

### セキュリティと権限

次の表は、セキュリティの観点のうち、この変更で変わるものを示す。

| 観点 | 内容 |
|---|---|
| 認可 | `task:complete` を認可 API に追加。画面のボタンの有無は守りではなく、BFF が必ず判定する |

認証、秘密情報、通信の暗号化、監査ログは既存の仕組みのまま（[0001 タスク管理](0001-task-management.md)）。

### データ

次の表は、データの観点のうち、この変更で変わるものを示す。

| 観点 | 内容 |
|---|---|
| 移行 | V3 で列を追加するだけ。既存の行は null（未完了）になり、切り戻しても壊れない |

扱う個人情報、保持期間、容量は変わらない。

### 性能と可用性、可観測性

次の表は、性能の観点でこの変更が増やす呼び出しを示す。学習用の構成なので目標値は置かない。

| 観点 | 内容 |
|---|---|
| 性能 | 詳細の表示で認可 API を 2 回呼ぶ（`task:read` と、`canComplete` のための `task:complete`）。学習用の規模（数百件、少人数）では問題にしない |

可用性と可観測性は変わらない。

### 展開と後始末

次の表は、展開の順序と、戻す方法、互換性を示す。

| 観点 | 内容 |
|---|---|
| 展開手順 | `api` を先に取り込み、api-client 1.1.0 を publish（契約から生成したクライアントを Maven リポジトリに登録すること。[ADR-0002 領域間のクライアントを成果物として配布する](../adr/ADR-0002-distribute-clients-as-artifacts.md)）する。次に `authz` に `task:complete` を足し、`web` が api-client 1.1.0 に追従し、最後に集約リポジトリの参照を更新する。古い BFF は `completedAt` を無視するので、この順に展開できる |
| 切り戻し | 集約リポジトリの `web` の参照を前のコミットに戻す。API の 1.1.0 は互換なので残してよい |
| 互換性 | 契約は追加のみ（互換）。古い BFF は新しい API と動く |
| 廃止計画 | なし。廃止する契約や機能は無い |

## 実装の段取り

実装済みのため該当しない。実装した順序は「展開と後始末」の表の「展開手順」の行のとおりで、`api`、`authz`、`web`、集約リポジトリの順にマージした。

## 未決事項

なし。2026-11-01 に次の 2 点を作成者（ht-0328）が決め、本文に反映した。

- 既に完了しているタスクへの完了操作 → 冪等にし、何もせず 200 で現状を返す（409 にしない）。理由は「比較した代替案とトレードオフ」の表にある
- 一覧で完了したタスクを既定で隠すか → 隠さない。全件を出し、状態の列の「完了」で見分ける（絞り込みは対象外）。理由は「比較した代替案とトレードオフ」の表にある

## 課題・申し送り事項

完了の取り消しと、一覧の絞り込み（完了したタスクを隠す）は、この設計に含めない。必要になったら別の設計で扱う。

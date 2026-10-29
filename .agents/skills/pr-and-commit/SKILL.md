---
name: pr-and-commit
description: >-
  fullstack-lab の 5 リポジトリでコミットし、PR を出し、CI を通してマージするときの流儀。
  コミットメッセージの書き方、PR 本文（テンプレート）の埋め方、サブモジュールの参照更新を含む。
  変更を取り込む段階になったら必ず使う。
---

# コミットと PR

## 1. コミット

- **Conventional Commits を日本語で**: `feat: …` `fix: …` `test: …` `docs: …` `chore: …` `refactor: …`。件名は変更の要点を 1 行、必要なら本文に理由を書きます。
- 例: `feat: タスクの完了状態を追加（契約 1.1.0）`、`fix: BFF の Docker ビルドで jar 取得時にも資格情報を渡す`。
- AI が書いたことを示す文言や、`Co-Authored-By` などの署名行は付けません。
- 1 コミット 1 目的。契約の変更と、それに追従する実装は分けると読みやすくなります。
- 生成コード、`.env`、`node_modules`、`build/` はコミットしません（各 `.gitignore`）。

## 2. ブランチと PR

- main は 5 リポジトリとも保護されています（PR と CI が必須）。ブランチ名は `feat/<slug>`、`fix/<slug>`、`test/<slug>`、`docs/<slug>`。
- PR の本文は各リポジトリの `.github/pull_request_template.md` に沿って書きます。

| 節 | 書くこと |
|---|---|
| 概要 | 何を変えるか 1〜3 行。設計書があればリンク |
| 実装内容 | 何をどう実装したか。**そう実装した意図**（他の選択肢と比べてなぜこれか）。契約や生成コードを変えたなら影響する呼び出し側 |
| テスト内容 | 実行したコマンドと結果。**その検証で十分だと判断した理由**（何を確かめ、何を確かめていないか） |
| 関連ドキュメント | 設計書、ADR、README の該当箇所。更新したならその旨 |
| 課題・申し送り事項 | 残課題、既知の制約、設計書とのずれ。なければ「なし」 |

- CI が通ったら squash merge（件名は Conventional Commits）。`gh pr merge --squash --delete-branch --subject "<件名>" --body ""`。
- マージの前に `gh pr checks --watch` で結果を確かめます。失敗したら `gh run view --log-failed` で原因を読み、同じブランチに `fix:` を積みます。

## 3. サブモジュールの参照更新

1. サブモジュール（`web` / `api` / `authz` / `auth`）の PR をマージし、`git -C <dir> checkout main && git -C <dir> pull`。
2. 集約リポジトリでブランチを切り、`git add <dir>` で参照先のコミットを進め、`chore: <dir> の参照を更新（<要点>）` でコミット。
3. 集約リポジトリの PR を出します。CI がサブモジュールを含めて Compose を起動し、スモークテスト・Karate・Playwright を実行します。

## 4. 契約を変えた PR の順序

提供側（`api` / `authz` / `auth`）→ マージ（CI が publish）→ 利用側（`web`）→ マージ → 集約（参照更新）。利用側の CI は提供側が publish した成果物を取得するため、この順で進めます。

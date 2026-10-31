---
name: writing-architecture-notes
description: >-
  references/architecture-notes（人が読む図解の HTML）のページを新しく作る、または既存のページ
  （HTML、SVG、assets/notes.css、README、index.html）を直すときに必ず使う。
  「〜の図解を作って」「図を見やすくして」「〜のページを直して」「アイコンを足して」と頼まれたときに使う。
  本体は references/architecture-notes/.agents/skills/writing-architecture-notes にあり、このスキルはそれを読んで従うための入口。
---

# 図解ページを書く・直す（入口）

本体は architecture-notes リポジトリの中にあります。Claude Code は fullstack-lab のルートからサブモジュールの中のスキルを検出しないので、この入口を置いています。中身をここに写さないでください。

1. [references/architecture-notes/.agents/skills/writing-architecture-notes/SKILL.md](../../../references/architecture-notes/.agents/skills/writing-architecture-notes/SKILL.md) を読み、その手順に従います。決まりの正典は [references/architecture-notes/README.md の「ページの書き方」](../../../references/architecture-notes/README.md#ページの書き方) です。
2. スクリプト（`check.py`、`screenshot.sh`）は `references/architecture-notes` の中で、あちらのルート基準のパスで実行します。
3. あちらの変更は、あちらのリポジトリで `docs/<slug>` ブランチを切って PR を出し（[pr-and-commit](../pr-and-commit/SKILL.md) の流儀）、マージ後に集約リポジトリで `references/architecture-notes` の参照を進める PR を別に出します。

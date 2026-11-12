# .agents/

AI コーディングエージェント向けの設定を置くディレクトリです。

- ルールの正典は [../AGENTS.md](../AGENTS.md)。Codex と Antigravity はこれを直接読みます。[../CLAUDE.md](../CLAUDE.md) は `@AGENTS.md` で取り込むだけです。
- スキルの正典は [skills/](skills/)。`.claude/skills` は `../.agents/skills` へのシンボリックリンクで、Claude Code はこれ経由で同じスキルを検出します。
- エージェント定義（Claude Code のサブエージェント。`design-review`、`doc-review`）は [../.claude/agents/](../.claude/agents/) にあります。他のツールに同じ仕組みが無いため、ここだけ Claude Code 固有です。

同じ内容を複数の場所にコピーしないでください。片方だけ更新されて食い違う原因になります。

| スキル | 使うとき |
|---|---|
| [writing-design-doc](skills/writing-design-doc/SKILL.md) | 機能の追加・変更の前に、設計の文書（`docs/design/<フォルダ>/`）を変更後の作りに直す、または足す |
| [writing-docs](skills/writing-docs/SKILL.md) | docs の文書を書く・直すときの共通の手順。`doc-review` エージェントで評価し、指摘を直して合格させ、`docs/review/` に記録する |
| [updating-openapi-contract](skills/updating-openapi-contract/SKILL.md) | `openapi/*.yaml` を変える（提供側の生成・publish と、利用側の追従） |
| [implementing-from-design](skills/implementing-from-design/SKILL.md) | 設計の文書に沿って実装し、テストし、PR を出す |
| [pr-and-commit](skills/pr-and-commit/SKILL.md) | コミット、PR 本文、CI、マージ、サブモジュールの更新 |
| [writing-architecture-notes](skills/writing-architecture-notes/SKILL.md) | `references/architecture-notes` の図解ページ（人が読む HTML）を作る、または直す。本体はあちらのリポジトリの `.agents/skills/` にあり、ここは入口 |

## 公式のスキル

このリポジトリのスキルは、手順を一から書かず、Anthropic が公開している公式のスキルを土台にしています。同じ手順を自前で書くと、公式の更新に追従できず、質も確かめにくいためです。次の表は、使っている公式のスキルと、どこから呼ぶかを示します。

| 公式のスキル | 出所 | 使うところ |
|---|---|---|
| `doc-coauthoring`（文脈の収集、節ごとの推敲、読者テストの 3 段で文書を書く） | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/doc-coauthoring)。プラグイン `example-skills@anthropic-agent-skills` | [writing-design-doc](skills/writing-design-doc/SKILL.md) の「文脈を集め、節ごとに書く」と「確かめる」の読者テスト |
| `skill-creator`（スキルを作る・直す、試して比べる、description を整える） | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)。プラグイン `skill-creator@claude-plugins-official` | このディレクトリのスキルを足す・直すとき |

Claude Code では、リポジトリのルートで次のコマンドを 1 回ずつ実行して入れます。`--scope project` を付けると、有効にするプラグインが `.claude/settings.json` に書かれ、リポジトリを開いた人に同じプラグインが案内されます。

```bash
claude plugin marketplace add anthropics/skills --scope project
claude plugin install example-skills@anthropic-agent-skills --scope project
claude plugin install skill-creator@claude-plugins-official --scope project
```

公式のスキルの本文は、このリポジトリに書き写しません。プラグインを入れていない環境のために、[writing-design-doc の references/coauthoring.md](skills/writing-design-doc/references/coauthoring.md) に進め方の要約だけを置いています。

スキルを足す・直すときは `skill-creator` を呼び、その手順（下書き、試す問いを 2〜3 個、直す前との比較、description の見直し）で進めます。

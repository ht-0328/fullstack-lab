# .agents/

AI コーディングエージェント向けの設定を置くディレクトリです。

- ルールの正典は [../AGENTS.md](../AGENTS.md)。Codex と Antigravity はこれを直接読みます。[../CLAUDE.md](../CLAUDE.md) は `@AGENTS.md` で取り込むだけです。
- スキルの正典は [skills/](skills/)。`.claude/skills` は `../.agents/skills` へのシンボリックリンクで、Claude Code はこれ経由で同じスキルを検出します。
- エージェント定義（Claude Code のサブエージェント）は [../.claude/agents/](../.claude/agents/) にあります。他のツールに同じ仕組みが無いため、ここだけ Claude Code 固有です。

同じ内容を複数の場所にコピーしないでください。片方だけ更新されて食い違う原因になります。

| スキル | 使うとき |
|---|---|
| [writing-design-doc](skills/writing-design-doc/SKILL.md) | 機能の追加・変更の設計書を書く、または更新する |
| [updating-openapi-contract](skills/updating-openapi-contract/SKILL.md) | `openapi/*.yaml` を変える（提供側の生成・publish と、利用側の追従） |
| [implementing-from-design](skills/implementing-from-design/SKILL.md) | 設計書に沿って実装し、テストし、PR を出す |
| [pr-and-commit](skills/pr-and-commit/SKILL.md) | コミット、PR 本文、CI、マージ、サブモジュールの更新 |

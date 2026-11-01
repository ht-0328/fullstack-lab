#!/usr/bin/env python3
"""docs/ の文書の形式を機械的に確かめる（doc-review が判定を揺らさないように、機械で決まる項目だけを見る）。

使い方:
  python3 scripts/doc-lint.py                 # docs/ の全文書
  python3 scripts/doc-lint.py docs/README.md  # 指定した文書だけ

確かめること（番号は docs/README.md の決まり）:
  F-2  先頭の表の 7 項目。設計書と ADR の状態の行
  F-5  相対リンクの先（ファイルと見出し）があること。リンクの表示文言がパスのままでないこと
  W-6  1 段落が 4 文まで（表、箇条書き、引用、コードブロックは除く）
  W-9  architecture/ の「用語」で決めた言い換え（本文で「版」と書かない）

1 件でも見つかれば終了コード 1 を返す。評価の記録（docs/review/docs-*.md）とテンプレートは対象外。
"""
import glob
import os
import re
import sys
import unicodedata

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
HEADER_ITEMS = ["発信日", "作成者", "機密区分", "保守責任者", "最終確認日", "想定読者（宛先）", "この文書を読んだあと読者ができること"]


def slug(heading: str) -> str:
    """GitHub の見出しアンカーの作り方に合わせる。"""
    s = heading.strip().lower()
    s = re.sub(r"`", "", s)
    out = []
    for ch in s:
        cat = unicodedata.category(ch)
        if ch in "-_ " or cat[0] in ("L", "N"):
            out.append("-" if ch == " " else ch)
    return "".join(out)


def headings(path: str) -> set:
    found, in_code = set(), False
    for line in open(path, encoding="utf-8"):
        if line.startswith("```"):
            in_code = not in_code
        if not in_code and re.match(r"^#{1,6} ", line):
            found.add(slug(re.sub(r"^#{1,6} ", "", line)))
    return found


def targets() -> list:
    if len(sys.argv) > 1:
        return [os.path.normpath(p) for p in sys.argv[1:]]
    files = glob.glob(os.path.join(ROOT, "docs", "**", "*.md"), recursive=True)
    return sorted(f for f in files
                  if not os.path.basename(f).startswith("docs-") and os.path.basename(f) != "TEMPLATE.md")


def check(path: str) -> list:
    rel = os.path.relpath(path, ROOT)
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")
    problems = []

    # F-2 先頭の表
    for item in HEADER_ITEMS:
        if not re.search(rf"^\| {re.escape(item)} \|", text, re.M):
            problems.append(("F-2", 1, f"先頭の表に「{item}」が無い"))
    if re.match(r".*docs/(design/\d{4}|adr/ADR-\d{4})", path) and "> **状態: " not in text:
        problems.append(("F-2", 1, "状態の行（> **状態: 〜。**）が無い"))

    # F-5 リンク
    in_code = False
    for n, line in enumerate(lines, 1):
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        for label, target in re.findall(r"\[([^\]]+)\]\(([^)\s]+)\)", line):
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            file_part, _, anchor = target.partition("#")
            dest = os.path.normpath(os.path.join(os.path.dirname(path), file_part)) if file_part else path
            if not os.path.exists(dest):
                problems.append(("F-5", n, f"リンク先が無い: {target}"))
                continue
            if anchor and dest.endswith(".md") and anchor not in headings(dest):
                problems.append(("F-5", n, f"見出しが無い: {target}"))
            if label.startswith(("../", "./")) or (label == target and "/" in target):
                problems.append(("F-5", n, f"表示文言がパスのまま: [{label}]"))

    # W-6 段落の文数 / W-9 用語
    in_code, para, start = False, [], 0
    def flush():
        joined = "".join(para)
        body = re.sub(r"`[^`]*`", "", joined)
        prev = None
        while prev != body:  # 入れ子の括弧も外す
            prev = body
            body = re.sub(r"\([^()]*\)|（[^（）]*）|「[^「」]*」", "", body)
        count = body.count("。")
        if count > 4:
            problems.append(("W-6", start, f"1 段落が {count} 文（4 文まで）"))
    for n, line in enumerate(lines, 1):
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        plain = line.strip()
        if plain and not re.match(r"^(\||#|>|- |\* |\d+\. |<!--)", plain):
            if not para:
                start = n
            para.append(plain)
        else:
            if para:
                flush()
            para = []
        body = re.sub(r"`[^`]*`|「[^」]*」", "", line)
        if re.search(r"(?<![出])版(?!本)", body) and not plain.startswith(("#", "| バージョン |")):
            problems.append(("W-9", n, "「版」と書いている（用語の表では「バージョン」）"))
    if para:
        flush()

    return [(rel, *p) for p in problems]


def main() -> int:
    all_problems = []
    for path in targets():
        all_problems += check(path)
    for rel, rule, line, msg in all_problems:
        print(f"{rel}:{line}: {rule} {msg}")
    print(f"doc-lint: {len(all_problems)} 件")
    return 1 if all_problems else 0


if __name__ == "__main__":
    sys.exit(main())

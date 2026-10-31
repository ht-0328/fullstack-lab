#!/usr/bin/env python3
# 図解ページの構造を確かめる。引数に HTML のパス（複数可）。問題があれば終了コード 1。
import pathlib, re, sys, xml.etree.ElementTree as ET

def check(path: pathlib.Path) -> list[str]:
    s = path.read_text(encoding="utf-8")
    problems = []
    for i, b in enumerate(re.findall(r'<svg[ >].*?</svg>', s, re.S)):
        try:
            ET.fromstring(re.sub(r'<svg', '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"', b, count=1))
        except ET.ParseError as e:
            problems.append(f"SVG {i} が整形式でない: {e}")
    ids = set(re.findall(r'\bid="([^"]+)"', s))
    for target in sorted(set(re.findall(r'href="#([^"]+)"', s))):
        if target not in ids and "…" not in target:
            problems.append(f"リンク先 #{target} が無い")
    for css in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"', s):
        if not (path.parent / css).exists():
            problems.append(f"CSS が見つからない: {css}")
    if s.count("<details") != s.count("</details>"):
        problems.append(f"<details> の対応がずれている: {s.count('<details')} / {s.count('</details>')}")
    for m in re.finditer(r'図 \d', s):
        if "aria-label" not in s[max(0, m.start() - 120):m.start()]:
            problems.append(f"本文に「{m.group(0)}」の参照が残っている（節の番号と名前で参照する）: …{s[max(0, m.start()-20):m.end()+10]!r}")
    if "<!-- TODO" in s or "TODO" in re.sub(r"<!--.*?-->", "", s, flags=re.S):
        problems.append("TODO が残っている")
    if "layer-head" in s:
        for cls in ("l1", "l2", "l3"):
            if f'class="layer-head {cls}"' not in s:
                problems.append(f"層の区切り layer-head {cls} が無い")
    if 'class="howto"' not in s and path.name != "index.html":
        problems.append("「読み方」（howto）が無い")
    return problems

bad = 0
for arg in sys.argv[1:]:
    p = pathlib.Path(arg)
    ps = check(p)
    print(f"{p}: {'OK' if not ps else str(len(ps)) + ' 件'}")
    for x in ps:
        print("  -", x)
    bad += len(ps)
sys.exit(1 if bad else 0)

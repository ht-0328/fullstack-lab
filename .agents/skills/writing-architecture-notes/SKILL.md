---
name: writing-architecture-notes
description: >-
  fullstack-lab-architecture-notes（references/architecture-notes。人が読む図解の HTML）のページを新しく作る、または既存のページ
  （HTML、SVG、assets/notes.css、README、index.html）を直すときに必ず使う。
  「〜の図解を作って」「図を見やすくして」「〜のページを直して」「アイコンを足して」と頼まれたときに使う。
  読者は「新しくチームに入った人」と「まだスキルの無い人」で、決まりの正典は references/architecture-notes/README.md の「ページの書き方」。
---

# 図解ページを書く・直す

## 1. 目的

新しくチームに入った人が「ぱっと見てすぐ分かり」、スキルの無い人でも「なんとなく内容が理解できる」ページを作ります。詳しさより先に分かりやすさを置き、読み進めるほど詳しくなる 3 層の作りにします。

## 2. 先に読むもの

1. [references/architecture-notes/README.md の「ページの書き方」](../../../references/architecture-notes/README.md#ページの書き方)。決まりの正典です。ここに書いてあることをこのファイルに写さず、必要ならあちらを直します。
2. [assets/notes.css](../../../references/architecture-notes/assets/notes.css)。共通の見た目と部品（`howto` `layer-head` `glossary` `strip` `details.deep` `legend` `cards` `callout` `ol.steps`、SVG のクラス）。
3. 型になるページ [auth/authentication-authorization.html](../../../references/architecture-notes/auth/authentication-authorization.html)。新しいページはこれと同じ順序・同じ部品で作ります。
4. 正となる文書。ページは fullstack-lab の設計書（`docs/design/`）と設定ファイルから読み取ったものなので、書く前にそちらを読み、食い違いがあればそちらに合わせます。

## 3. 新しいページを作る

1. [template.html](template.html) を `references/architecture-notes/<領域>/<slug>.html` にコピーし、`<!-- TODO -->` を順に埋めます。順序は変えません（見出し → 導入 3 文 → 読み方 → 層ごとの目次 → 層 1 → 層 2 → 層 3 → フッター）。
2. **層 1 から書きます**。01 は図 1 枚と 3 行で結論。02 は登場人物の凡例と「まず覚える言葉」（8 語まで）。ここだけ読んだ人が会話についていけるかを基準にします。
3. 層 2 の各節は、先頭に `strip`（3〜4 コマの要約）、次に図、長い手順の説明は `details.deep` に入れます。
4. 層 3 は見出しと導入 1 文だけ見せ、表や値は `details.deep` に入れます。
5. 図は HTML 内の SVG で描き、色と文字サイズは `notes.css` のクラスを使います（直書きしない）。同じ役割には既存ページと同じアイコン・同じ色。アイコンを増やすときは「5. 図とアイコン」。
6. `index.html` の一覧と README の表に 1 行足します（読み取った時点の日付つき）。
7. 「6. 確認」を通してから「7. 取り込み」へ。

## 4. 既存のページを直す

1. 直す前にページ全体を読み、どの層のどの節に当たる変更かを決めます。層 1 に詳細を足さない、層 3 の内容を層 1 に持ち込まない、が原則です。
2. **文章も図も両方直します**。図だけ、文章だけ直して食い違いを残しません。図の番号や節の番号を本文で参照している箇所（「04 ログインの流れ」など）を検索して追従します。
3. 色・アイコン・言葉は既存の意味に合わせます。新しい意味の色やアイコンが必要なら、README の表と凡例にも足します。
4. SVG を直すときは、文字の幅を見積もって箱からはみ出さないようにし、必ず描画して確かめます（「6. 確認」）。
5. 読み取った設定が変わったなら、フッター・README の表・`index.html` の「時点」を更新します。
6. `notes.css` を変えたときは全ページを描画して確かめます。ページ固有の装飾は `notes.css` に入れず、そのページの `<style>` に残します。

## 5. 図とアイコン

- SVG は `viewBox` で描き、`.fig-scroll` の中に置きます。シーケンス図は `class="seq"`、構成図は `class="arch"`。
- 文字は `t11` `t12` `t13`（太字）、色は `tm`（補足）`tc`（一般利用者）`ts`（社員）`tk`（IdP）`tj`（JWT）`tz`（認可）`tau`（認証 API）`tok` `tng`。線は `ln` + `c` `s` `k` `jwt` `z` `au`、箱は `box` + 同じ色クラス。
- 仕組みの部品のアイコンは Font Awesome Free（CC BY 4.0）、製品ロゴは Simple Icons（CC0）。取り方:
  ```bash
  curl -sS -o key.svg https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/svgs/solid/key.svg
  curl -sS -o nginx.svg https://raw.githubusercontent.com/simple-icons/simple-icons/16.36.0/icons/nginx.svg
  ```
  `viewBox` と `<path d>` を取り出して `<body>` 先頭の `<svg>` に `<symbol id="i-<name>" viewBox="…"><path d="…"/></symbol>` として足し、図からは `<use href="#i-<name>" class="ic k" x y width height/>` で参照します。ファイルは置きません（CSS で色を変えるため）。`<symbol>` の直前のコメントに名前と版を足し、README の「更新のきまり」の版と合わせます。
- AWS のサービスは公式 Architecture Icons を `assets/aws-icons/` に改変せず置き、`<image href>` で Light / Dark の 2 枚を参照します（`ic-l` / `ic-d`）。

## 6. 確認

1. 構造の確認。SVG の整形式、目次のリンク先、CSS のパス、折りたたみの対応、残った「図 N」参照、`<use>` の参照先を調べます。
   ```bash
   python3 -I .agents/skills/writing-architecture-notes/scripts/check.py references/architecture-notes/auth/authentication-authorization.html
   ```
2. 描画の確認。ホストにブラウザが無いので、e2e と同じ Playwright の Docker イメージで撮ります。先頭 1 画面（ライト / ダーク）、各図、読み方、凡例、用語集、要約、折りたたみ（閉じた状態と開いた状態）が出ます。画像を Read で開いて、文字のはみ出し、重なり、色の意味のずれを目で確かめます。
   ```bash
   .agents/skills/writing-architecture-notes/scripts/screenshot.sh references/architecture-notes auth/authentication-authorization.html /tmp/shots
   ```
3. `file://` で直接開いても壊れないこと（外部ファイルは `notes.css` と Google Fonts だけ。`<use>` は同じ HTML 内の `<symbol>` を指す）。
4. 本文の事実が fullstack-lab の設計書・設定と一致していること。仮定や未決は「仮定」「未決」と書く。

## 7. 取り込み

- architecture-notes は独立したリポジトリです。`docs/<slug>` ブランチを切り、[pr-and-commit](../pr-and-commit/SKILL.md) の流儀でコミットと PR を出します（PR 本文の「テスト内容」には上の確認で何を見たかを書く）。
- マージ後、fullstack-lab 側で `references/architecture-notes` の参照コミットを進める PR を別に出します。
- push と PR はユーザーに確認してから行います。

## 8. 制約

- 秘密情報（`.env` の値、シークレット）をページに書きません。
- 外部のライブラリ（JS、CSS フレームワーク）を足しません。JS は視点の切り替えのような最小限のものだけ。
- 依頼されていないページやファイルを変えません。`notes.css` を変えるときは、その影響が全ページに及ぶことを PR に書きます。

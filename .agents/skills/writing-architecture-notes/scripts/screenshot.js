// 図解ページを要素ごとに撮る。screenshot.sh から Playwright の Docker イメージの中で実行する。
// 使い方: node screenshot.js <page の URL> <出力ディレクトリ>
const { chromium } = require('playwright');
const [url, out] = process.argv.slice(2);
(async () => {
  const browser = await chromium.launch();
  for (const scheme of ['light', 'dark']) {
    const ctx = await browser.newContext({ viewport: { width: 1100, height: 900 }, colorScheme: scheme, deviceScaleFactor: 2 });
    const page = await ctx.newPage();
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(600);
    await page.screenshot({ path: `${out}/${scheme}-top.png`, clip: { x: 0, y: 0, width: 1100, height: 900 } });
    console.log(`${scheme}-top`);
    if (scheme === 'dark') { await ctx.close(); continue; }
    const targets = [['howto', '.howto'], ['toc', 'nav.toc'], ['legend', '.legend'], ['glossary', '.glossary'], ['cards', '.cards']];
    for (const [name, sel] of targets) {
      const loc = page.locator(sel).first();
      if (await loc.count()) { await loc.scrollIntoViewIfNeeded(); await loc.screenshot({ path: `${out}/${name}.png` }); console.log(name); }
    }
    const figs = page.locator('figure'); const nf = await figs.count();
    for (let i = 0; i < nf; i++) { const f = figs.nth(i); await f.scrollIntoViewIfNeeded(); await f.screenshot({ path: `${out}/fig${i + 1}.png` }); console.log(`fig${i + 1}`); }
    const strips = page.locator('ol.strip'); const ns = await strips.count();
    for (let i = 0; i < ns; i++) { const f = strips.nth(i); await f.scrollIntoViewIfNeeded(); await f.screenshot({ path: `${out}/strip${i + 1}.png` }); console.log(`strip${i + 1}`); }
    const details = page.locator('details.deep'); const nd = await details.count();
    for (let i = 0; i < nd; i++) {
      const d = details.nth(i); await d.scrollIntoViewIfNeeded();
      await d.screenshot({ path: `${out}/details${i + 1}-closed.png` });
      await d.locator('summary').click(); await page.waitForTimeout(150);
      await d.screenshot({ path: `${out}/details${i + 1}-open.png` }); console.log(`details${i + 1}`);
    }
    await page.screenshot({ path: `${out}/full.png`, fullPage: true }); console.log('full');
    await ctx.close();
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });

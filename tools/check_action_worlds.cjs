const { chromium } = require('../experiments/rivet/node_modules/playwright-core');
const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const root = path.resolve(__dirname, '../experiments');

(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/google-chrome',
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });

  for (const slug of ['veylifter', 'undertow-bloom', 'mixtape-mile']) {
    for (const mobile of [false, true]) {
      const context = await browser.newContext({
        viewport: mobile ? { width: 390, height: 844 } : { width: 1365, height: 768 },
        isMobile: mobile,
        hasTouch: mobile,
        deviceScaleFactor: 1,
      });
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', error => errors.push(error.message));
      await page.goto(pathToFileURL(path.join(root, slug, 'index.html')).href);
      await page.locator('#start').click();
      await page.waitForTimeout(600);
      assert.equal(await page.locator('body').getAttribute('class'), 'playing');
      assert.equal(await page.locator('#hud').isVisible(), true);
      if (mobile) assert.equal(await page.locator('#action').isVisible(), true);

      if (slug === 'mixtape-mile') {
        if (mobile) await page.locator('#action').tap();
        else {
          await page.keyboard.press('ArrowUp');
          await page.keyboard.press('Space');
        }
        assert.match(await page.locator('#energy').innerText(), /[1-9] \/ 6/);
      } else if (mobile) {
        await page.locator('#action').tap();
      } else {
        await page.keyboard.down('ArrowRight');
        await page.waitForTimeout(600);
        await page.keyboard.up('ArrowRight');
        await page.keyboard.press('Space');
      }
      assert.deepEqual(errors, [], `${slug} ${mobile ? 'phone' : 'desktop'} errors`);
      console.log(`${slug} ${mobile ? 'phone' : 'desktop'} passed`);
      await context.close();
    }
  }

  await browser.close();
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});

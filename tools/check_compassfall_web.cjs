const { spawn } = require('node:child_process');
const { mkdir } = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require('../experiments/rivet/node_modules/playwright');

async function main() {
  const project = path.resolve(__dirname, '..', 'experiments', 'compassfall');
  const server = spawn('python3', ['-m', 'http.server', '8768', '--directory', path.join(project, 'build', 'web')], { stdio: 'ignore' });
  let browser;
  try {
    for (let attempt = 0; attempt < 50; attempt++) {
      try {
        if ((await fetch('http://127.0.0.1:8768/')).ok) break;
      } catch (_) { /* Server is starting. */ }
      if (attempt === 49) throw new Error('Web server did not start');
      await new Promise(resolve => setTimeout(resolve, 200));
    }
    browser = await chromium.launch({ headless: true, executablePath: process.env.CHROME_PATH, args: [
      '--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'
    ] });
    const page = await browser.newPage({ viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true });
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    await page.goto('http://127.0.0.1:8768/', { timeout: 180000 });
    await page.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
    if (await page.locator('#error').textContent()) throw new Error(await page.locator('#error').textContent());
    let marker = page.waitForEvent('console', { predicate: message => message.text().includes('COMPASSFALL_START 0'), timeout: 10000 });
    await page.touchscreen.tap(422, 277);
    await marker;
    await page.waitForTimeout(600);
    const cdp = await page.context().newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 120, y: 355, id: 0 }] });
    marker = page.waitForEvent('console', { predicate: message => message.text().includes('COMPASSFALL_JUMP'), timeout: 10000 });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [
      { x: 120, y: 355, id: 0 }, { x: 611, y: 355, id: 1 }
    ] });
    await marker;
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [{ x: 120, y: 355, id: 0 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    marker = page.waitForEvent('console', { predicate: message => message.text().includes('COMPASSFALL_SHIFT'), timeout: 10000 });
    await page.touchscreen.tap(716, 357);
    await marker;
    if (errors.length) throw new Error(errors.join('\n'));
    const results = path.join(project, 'test-results');
    await mkdir(results, { recursive: true });
    await page.screenshot({ path: path.join(results, 'mobile.png') });
    console.log('MOBILE_WEB_OK compassfall');
  } finally {
    if (browser) await browser.close();
    if (server.exitCode === null) {
      server.kill();
      await new Promise(resolve => server.once('exit', resolve));
    }
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });

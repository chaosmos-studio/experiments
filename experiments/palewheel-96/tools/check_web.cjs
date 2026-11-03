const { spawn } = require('node:child_process');
const { mkdir } = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require('playwright');

async function main() {
  const project = path.resolve(__dirname, '..');
  const server = spawn('python3', ['-m', 'http.server', '8769', '--directory', path.join(project, 'build', 'web')], { stdio: 'ignore' });
  let browser;
  try {
    for (let attempt = 0; attempt < 50; attempt++) {
      try {
        if ((await fetch('http://127.0.0.1:8769/')).ok) break;
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
    await page.goto('http://127.0.0.1:8769/', { timeout: 180000 });
    await page.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
    if (await page.locator('#error').textContent()) throw new Error(await page.locator('#error').textContent());
    await page.waitForTimeout(800);
    if (errors.length) throw new Error(errors.join('\n'));
    const results = path.join(project, 'test-results');
    await mkdir(results, { recursive: true });
    await page.screenshot({ path: path.join(results, 'intro.png') });
    let marker = page.waitForEvent('console', { predicate: message => message.text().includes('PALEWHEEL_START 0'), timeout: 10000 });
    await page.touchscreen.tap(240, 292);
    await marker;
    await page.waitForTimeout(600);
    const cdp = await page.context().newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 105, y: 353, id: 0 }] });
    await page.waitForTimeout(240);
    await page.screenshot({ path: path.join(results, 'run.png') });
    marker = page.waitForEvent('console', { predicate: message => message.text().includes('PALEWHEEL_JUMP'), timeout: 10000 });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [
      { x: 105, y: 353, id: 0 }, { x: 573, y: 350, id: 1 }
    ] });
    await marker;
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [{ x: 105, y: 353, id: 0 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(120);
    await page.screenshot({ path: path.join(results, 'jump.png') });
    marker = page.waitForEvent('console', { predicate: message => message.text().includes('PALEWHEEL_SHIFT'), timeout: 10000 });
    await page.touchscreen.tap(640, 350);
    await marker;
    if (errors.length) throw new Error(errors.join('\n'));
    await page.screenshot({ path: path.join(results, 'mobile.png') });
    const desktop = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    await desktop.goto('http://127.0.0.1:8769/', { timeout: 180000 });
    await desktop.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
    await desktop.waitForTimeout(800);
    const desktopStart = desktop.waitForEvent('console', { predicate: message => message.text().includes('PALEWHEEL_START 0'), timeout: 10000 });
    await desktop.mouse.click(200, 545);
    await desktopStart;
    await desktop.screenshot({ path: path.join(results, 'desktop.png') });
    for (const [room, world] of [[1, 'array'], [2, 'freight'], [3, 'core']]) {
      const preview = await browser.newPage({ viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true });
      const previewErrors = [];
      preview.on('pageerror', error => previewErrors.push(String(error)));
      const roomLoaded = preview.waitForEvent('console', { predicate: message => message.text().includes(`PALEWHEEL_ROOM ${room}`), timeout: 90000 });
      await preview.goto(`http://127.0.0.1:8769/?room=${room}`, { timeout: 180000 });
      await roomLoaded;
      await preview.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
      const started = preview.waitForEvent('console', { predicate: message => message.text().includes(`PALEWHEEL_START ${room}`), timeout: 10000 });
      await preview.touchscreen.tap(240, 292);
      await started;
      await preview.waitForTimeout(400);
      await preview.screenshot({ path: path.join(results, `${world}.png`) });
      if (previewErrors.length) throw new Error(previewErrors.join('\n'));
      await preview.close();
    }
    console.log('MOBILE_WEB_OK palewheel-96');
  } finally {
    if (browser) await browser.close();
    if (server.exitCode === null) {
      server.kill();
      await new Promise(resolve => server.once('exit', resolve));
    }
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });

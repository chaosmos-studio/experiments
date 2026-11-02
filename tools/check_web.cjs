const { spawn } = require('node:child_process');
const { mkdir } = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require('../experiments/rivet/node_modules/playwright');

async function run() {
  const game = process.argv[2];
  if (!['phasewalk', 'rowshift'].includes(game)) throw new Error('Choose phasewalk or rowshift');
  const project = path.resolve(__dirname, '..', 'experiments', game);
  const web = path.join(project, 'build', 'web');
  const server = spawn('python3', ['-m', 'http.server', '8765', '--directory', web], {
    stdio: process.env.DEBUG_WEB ? 'inherit' : 'ignore'
  });
  let browser;
  try {
    for (let attempt = 0; attempt < 50; attempt++) {
      try {
        const response = await fetch('http://127.0.0.1:8765/index.html');
        if (response.ok) break;
      } catch (_) { /* The server is still starting. */ }
      if (attempt === 49) throw new Error('Web server did not start');
      await new Promise(resolve => setTimeout(resolve, 200));
    }
    browser = await chromium.launch({headless: true, executablePath: process.env.CHROME_PATH, args: [
      '--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'
    ]});
    const page = await browser.newPage({viewport: {width: 390, height: 844}, isMobile: true, hasTouch: true});
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    page.on('requestfailed', request => console.error('REQUEST_FAILED', request.url(), request.failure()));
    page.on('console', message => {
      if (message.type() === 'error') console.error('BROWSER_ERROR', message.text());
    });
    console.log(`Opening ${game} in a phone browser`);
    await page.goto('http://127.0.0.1:8765/', {timeout: 180000});
    await page.waitForFunction(() => {
      return document.getElementById('loading')?.hidden || !document.getElementById('retry')?.hidden;
    }, null, {timeout: 90000});
    if (await page.locator('#error').textContent()) throw new Error(await page.locator('#error').textContent());
    const tap = game === 'phasewalk' ? {x: 325, y: 610} : {x: 328, y: 330};
    const expected = game === 'phasewalk' ? 'PHASEWALK_STATE 1 1' : 'ROWSHIFT_MOVES 1';
    const action = page.waitForEvent('console', {
      predicate: message => message.text().includes(expected),
      timeout: 10000
    });
    await page.touchscreen.tap(tap.x, tap.y);
    await action;
    if (errors.length) throw new Error(errors.join('\n'));
    await mkdir(path.join(project, 'test-results'), {recursive: true});
    await page.screenshot({path: path.join(project, 'test-results', 'mobile.png')});
    console.log(`MOBILE_WEB_OK ${game}`);
  } finally {
    if (browser) await browser.close();
    if (server.exitCode === null) {
      server.kill();
      await new Promise(resolve => server.once('exit', resolve));
    }
  }
}

run().catch(error => {console.error(error); process.exitCode = 1;});

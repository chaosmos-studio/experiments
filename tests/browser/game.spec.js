const {test, expect} = require('@playwright/test');

test('loads real Godot, plays a level, undoes, and opens help', async ({page}, testInfo) => {
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', msg => {if (/SCRIPT ERROR|Parse Error|ERROR:/.test(msg.text())) errors.push(msg.text());});
  await page.goto('/');
  await page.waitForFunction(() => window.rivetReady === true, null, {timeout: 90000});
  await expect(page.locator('#loading')).toBeHidden();
  const vp = page.viewportSize();
  const scale = Math.min(vp.width/720, vp.height/1000);
  const ox = (vp.width-720*scale)/2, oy = (vp.height-1000*scale)/2;
  async function tap(x,y) {
    if(testInfo.project.name === 'mobile') await page.touchscreen.tap(ox+x*scale,oy+y*scale);
    else await page.mouse.click(ox+x*scale,oy+y*scale);
    await page.waitForTimeout(450);
  }
  await page.screenshot({path:testInfo.outputPath('first-study.png')});
  // Actual UI clicks: collect, undo, collect a triple, then solve the tutorial.
  await tap(264,370);
  await expect(page.locator('#game-state')).toHaveAttribute('data-tray','1');
  await tap(150,917);
  await expect(page.locator('#game-state')).toHaveAttribute('data-tray','0');
  for (const [x,y] of [[264,370],[264,472],[264,574]]) await tap(x,y);
  await expect(page.locator('#game-state')).toHaveAttribute('data-sets','1');
  await page.screenshot({path:testInfo.outputPath('one-set.png')});
  for (const x of [360,456]) for(const y of [370,472,574]) await tap(x,y);
  await expect(page.locator('#game-state')).toHaveAttribute('data-screen','won');
  await page.screenshot({path:testInfo.outputPath('completed-study.png')});
  // The win screen's primary button starts study 2.
  await tap(360,574);
  await expect(page.locator('#game-state')).toHaveAttribute('data-level','2');
  await tap(640,65);
  await expect(page.locator('#game-state')).toHaveAttribute('data-screen','help');
  await page.screenshot({path:testInfo.outputPath('help.png')});
  expect(errors).toEqual([]);
  const canvas = page.locator('canvas');
  await expect(canvas).toBeVisible();
  // Confirm the packaged engine was loaded from all ten actual WASM chunks.
  const resources=await page.evaluate(()=>performance.getEntriesByType('resource').map(r=>r.name));
  expect(resources.filter(url=>/index\.wasm\.part\d+$/.test(url)).length).toBe(10);
});

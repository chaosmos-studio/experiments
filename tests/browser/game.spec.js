const {test, expect} = require('@playwright/test');
const campaign = require('../../data/levels.json');

test('real Godot: lose, recover, plan a win, and inspect hidden layers', async ({page}, testInfo) => {
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', msg => {if (/SCRIPT ERROR|Parse Error|ERROR:/.test(msg.text())) errors.push(msg.text());});
  await page.goto('/');
  await page.waitForFunction(() => window.rivetReady === true, null, {timeout: 90000});
  await expect(page.locator('#loading')).toBeHidden();
  const state = page.locator('#game-state');
  await expect(state).toHaveAttribute('data-campaign','2');
  const vp = page.viewportSize();
  const scale = Math.min(vp.width/720, vp.height/1000);
  const ox = (vp.width-720*scale)/2, oy = (vp.height-1000*scale)/2;
  async function tap(x,y) {
    if(testInfo.project.name === 'mobile') await page.touchscreen.tap(ox+x*scale,oy+y*scale);
    else await page.mouse.click(ox+x*scale,oy+y*scale);
    await page.waitForTimeout(450);
  }
  async function screw(index) {
    const s = campaign[0].screws[index];
    const before = BigInt(await state.getAttribute('data-removed'));
    await tap(74+s.x,266+s.y);
    await expect(state).toHaveAttribute('data-removed',String(before | (1n << BigInt(index))));
  }
  await page.screenshot({path:testInfo.outputPath('first-study.png')});
  await screw(campaign[0].solution[0]);
  await expect(state).toHaveAttribute('data-tray','1');
  await tap(150,917);
  await expect(state).toHaveAttribute('data-tray','0');
  // A legal but poor order must genuinely lose, even in study 1.
  for (const index of campaign[0].failure_route) await screw(index);
  await expect(state).toHaveAttribute('data-screen','lost');
  await expect(state).toHaveAttribute('data-tray','7');
  await page.screenshot({path:testInfo.outputPath('lost-study.png')});
  await tap(230,574);
  await expect(state).toHaveAttribute('data-screen','play');
  await expect(state).toHaveAttribute('data-tray','6');
  await tap(560,917);
  await expect(state).toHaveAttribute('data-tray','0');
  // Inspection reveals information without solving the board or spending a hint.
  await tap(362,65);
  await expect(state).toHaveAttribute('data-screen','inspect');
  await expect(state).toHaveAttribute('data-hints','0');
  await page.screenshot({path:testInfo.outputPath('inspect-study.png')});
  await tap(360,848);
  let mask=0n;
  for (const index of campaign[0].solution) {
    await screw(index);
    mask |= 1n << BigInt(index);
    await expect(state).toHaveAttribute('data-removed',String(mask));
  }
  await expect(state).toHaveAttribute('data-screen','won');
  await expect(state).toHaveAttribute('data-undos','0');
  await expect(state).toHaveAttribute('data-hints','0');
  await page.screenshot({path:testInfo.outputPath('completed-study.png')});
  await tap(360,574);
  await expect(state).toHaveAttribute('data-level','2');
  await tap(640,65);
  await expect(state).toHaveAttribute('data-screen','help');
  await page.screenshot({path:testInfo.outputPath('help.png')});
  await tap(490,751);
  await tap(480,65);
  await tap(580,686);
  await expect(state).toHaveAttribute('data-level','36');
  await page.screenshot({path:testInfo.outputPath('master-study.png')});
  await tap(362,65);
  await expect(state).toHaveAttribute('data-screen','inspect');
  await page.screenshot({path:testInfo.outputPath('master-inspect.png')});
  expect(errors).toEqual([]);
  await expect(page.locator('canvas')).toBeVisible();
  const resources=await page.evaluate(()=>performance.getEntriesByType('resource').map(r=>r.name));
  expect(resources.filter(url=>/index\.wasm\.part\d+$/.test(url)).length).toBe(10);
});

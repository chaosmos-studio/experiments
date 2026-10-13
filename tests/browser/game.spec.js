const {test, expect} = require('@playwright/test');
const campaign = require('../../data/levels.json');

test('real Godot: ordered matches, returns, full tray recovery, and a clean win', async ({page}, testInfo) => {
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', msg => {if (/SCRIPT ERROR|Parse Error|ERROR:/.test(msg.text())) errors.push(msg.text());});
  await page.goto('/');
  await page.waitForFunction(() => window.rivetReady === true, null, {timeout: 90000});
  await expect(page.locator('#loading')).toBeHidden();
  const state = page.locator('#game-state');
  await expect(state).toHaveAttribute('data-campaign','3');
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
  const demo = campaign[0].return_demo;
  for (const index of demo.takes) await screw(index);
  await expect(state).toHaveAttribute('data-order', demo.takes.join(','));
  await expect(state).toHaveAttribute('data-sets','0');
  await page.screenshot({path:testInfo.outputPath('ordered-tray.png')});
  const demoMask = BigInt(await state.getAttribute('data-removed'));
  await tap(192,818); // A B A A: return B to close the gap and clear A A A.
  await expect(state).toHaveAttribute('data-tray','0');
  await expect(state).toHaveAttribute('data-sets','1');
  await expect(state).toHaveAttribute('data-returns','1');
  await expect(state).toHaveAttribute('data-removed',String(demoMask & ~(1n << BigInt(demo.return_id))));
  await page.screenshot({path:testInfo.outputPath('returned-screw.png')});
  await tap(150,917);
  await expect(state).toHaveAttribute('data-order',demo.takes.join(','));
  await expect(state).toHaveAttribute('data-sets','0');
  await expect(state).toHaveAttribute('data-removed',String(demoMask));
  await tap(560,917);
  for (const index of campaign[0].full_route) await screw(index);
  await expect(state).toHaveAttribute('data-screen','full');
  await expect(state).toHaveAttribute('data-tray','7');
  await page.screenshot({path:testInfo.outputPath('full-tray.png')});
  const fullMask = BigInt(await state.getAttribute('data-removed'));
  const fullOrder = (await state.getAttribute('data-order')).split(',').map(Number);
  // A full tray still allows inspection and returns.
  await tap(362,65);
  await expect(state).toHaveAttribute('data-screen','inspect');
  await page.screenshot({path:testInfo.outputPath('inspect-study.png')});
  await tap(360,848);
  await expect(state).toHaveAttribute('data-screen','full');
  // Board input is blocked while full.
  const blocked = campaign[0].screws.findIndex((_,i)=>!(fullMask & (1n << BigInt(i))));
  const s = campaign[0].screws[blocked];
  await tap(74+s.x,266+s.y);
  await expect(state).toHaveAttribute('data-removed',String(fullMask));
  if(testInfo.project.name === 'mobile') await tap(108,818);
  else await page.keyboard.press('1');
  await expect(state).toHaveAttribute('data-screen','play');
  await expect(state).toHaveAttribute('data-removed',String(fullMask & ~(1n << BigInt(fullOrder[0]))));
  // Finish with a return and no hints or undo. Returns are ordinary play.
  await tap(560,917);
  for (const index of demo.takes) await screw(index);
  await tap(192,818);
  for (const index of demo.after) await screw(index);
  await expect(state).toHaveAttribute('data-screen','won');
  await expect(state).toHaveAttribute('data-tray','0');
  await expect(state).toHaveAttribute('data-undos','0');
  await expect(state).toHaveAttribute('data-hints','0');
  await expect(state).toHaveAttribute('data-returns','1');
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

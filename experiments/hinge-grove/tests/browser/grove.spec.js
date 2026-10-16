const {test,expect}=require('@playwright/test');
const campaign=require('../../data/levels.json').levels;
const audit=require('../../docs/audit.json');

test('real input, rooted mistakes, undo, hints, audio, persistence and ending',async({page},info)=>{
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(/SCRIPT ERROR|Parse Error|ERROR:/.test(m.text()))errors.push(m.text())});
  await page.addInitScript(()=>{
    window.audioProbes=[];const Native=window.AudioContext||window.webkitAudioContext;if(!Native)return;
    const observed=new WeakMap();
    window.AudioContext=class extends Native{constructor(...args){super(...args);const a=this.createAnalyser();a.fftSize=2048;observed.set(this,a);window.audioProbes.push(a)}};
    const connect=AudioNode.prototype.connect;
    AudioNode.prototype.connect=function(destination,...args){const a=observed.get(this.context);if(a&&destination===this.context.destination)connect.call(this,a);return connect.call(this,destination,...args)};
    window.audioPeak=()=>Math.max(0,...window.audioProbes.map(a=>{const s=new Float32Array(a.fftSize);a.getFloatTimeDomainData(s);return Math.max(...s.map(Math.abs))}));
  });
  await page.goto('/');
  await page.waitForFunction(()=>window.hingeReady&&window.hingeState?.buttons.length>0,null,{timeout:90000});
  await expect(page.locator('#loading')).toBeHidden();
  const read=()=>page.evaluate(()=>window.hingeState);
  const tap=async point=>{
    const s=await read(), box=await page.locator('canvas').boundingBox();
    const x=box.x+point[0]/s.viewport[0]*box.width,y=box.y+point[1]/s.viewport[1]*box.height;
    if(info.project.name==='mobile')await page.touchscreen.tap(x,y);else await page.mouse.click(x,y);
    await page.waitForTimeout(90);
  };
  const action=async id=>{
    await page.waitForFunction(id=>window.hingeState.buttons.some(b=>b.id===id),id);
    const s=await read();await tap(s.buttons.find(b=>b.id===id).center);
  };
  const play=async move=>{
    const s=await read();await tap(s.cells[move[1]]);
    await page.waitForFunction(m=>window.hingeState.selected===m[1],move);
    const chosen=(await read()).choices.find(c=>c.piece===move[0]&&c.turn===move[2]);
    expect(chosen,'actual view offers the solver move').toBeTruthy();
    await tap((await read()).cells[chosen.to]);
    await page.waitForFunction(n=>window.hingeState.moves===n&&!window.hingeState.busy,s.moves+1);
  };
  const open=async index=>{
    await action('levels');await page.waitForFunction(()=>window.hingeState.screen==='levels');
    if(!(await read()).buttons.some(b=>b.id==='level_'+index))await action('page');
    await action('level_'+index);await page.waitForFunction(i=>window.hingeState.level===i+1&&window.hingeState.screen==='play',index);
  };
  expect((await read()).count).toBe(30);
  await page.screenshot({path:info.outputPath('01-first-garden.png')});
  const original=JSON.stringify((await read()).state);
  await action('hint');
  expect((await read()).moves).toBe(0);
  await page.screenshot({path:info.outputPath('02-hint.png')});
  await play(campaign[0].solution[0]);
  await page.waitForFunction(()=>window.audioPeak()>0.001,null,{timeout:10000});
  await action('undo');
  expect(JSON.stringify((await read()).state)).toBe(original);
  expect((await read()).moves).toBe(0);
  for(const move of campaign[0].solution)await play(move);
  await page.waitForFunction(()=>window.hingeState.won);
  await page.waitForTimeout(500);
  expect((await read()).buttons.some(b=>['undo','hint','reset'].includes(b.id))).toBe(false);
  await page.screenshot({path:info.outputPath('03-bloom.png')});
  await action('next');expect((await read()).level).toBe(2);
  await open(audit.dead_end_fixture.level-1);
  for(const move of audit.dead_end_fixture.moves)await play(move);
  expect((await read()).won).toBe(false);
  await action('hint');
  expect((await read()).message).toContain('blocks the route');
  await page.screenshot({path:info.outputPath('04-consequence.png')});
  await action('undo');
  expect((await read()).moves).toBe(audit.dead_end_fixture.moves.length-1);
  await action('reset');
  expect((await read()).moves).toBe(0);
  for(const move of campaign[audit.dead_end_fixture.level-1].solution)await play(move);
  await page.waitForFunction(()=>window.hingeState.won);
  for(const index of [18,29]){
    await open(index);
    await page.screenshot({path:info.outputPath('garden-'+(index+1)+'.png')});
    for(const move of campaign[index].solution)await play(move);
    await page.waitForFunction(()=>window.hingeState.won);
  }
  await page.waitForTimeout(550);await action('next');
  expect((await read()).screen).toBe('ending');
  await page.screenshot({path:info.outputPath('05-ending.png')});
  await action('close');await action('settings');
  await action('music');await action('sound');await action('motion');
  await page.waitForTimeout(400);
  expect((await read()).music).toBe(false);expect((await read()).sound).toBe(false);
  await page.waitForFunction(()=>window.audioPeak()<0.00001);
  await page.screenshot({path:info.outputPath('06-settings.png')});
  await page.reload();await page.waitForFunction(()=>window.hingeReady&&window.hingeState?.buttons.length>0);
  expect((await read()).level).toBe(30);expect((await read()).music).toBe(false);expect((await read()).sound).toBe(false);expect((await read()).motion).toBe(true);
  await open(0);await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowRight');await page.keyboard.press('Enter');
  await page.waitForFunction(()=>window.hingeState.selected===3);
  await page.keyboard.press('ArrowLeft');await page.keyboard.press('Enter');
  await page.waitForFunction(()=>window.hingeState.moves===1&&!window.hingeState.busy);
  await page.keyboard.press('z');await page.waitForFunction(()=>window.hingeState.moves===0);
  expect(errors).toEqual([]);
});

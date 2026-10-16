const {test,expect}=require('@playwright/test');
const campaign=require('../../data/levels.json').levels;
const audit=require('../../docs/audit.json');

test('friendly controls, visible growth, saved gardens and recovery',async({page},info)=>{
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
  const ready=()=>page.waitForFunction(()=>window.hingeReady&&window.hingeState?.version===2&&window.hingeState.buttons.length>0,null,{timeout:90000});
  await ready();
  await expect(page.locator('#loading')).toBeHidden();
  const read=()=>page.evaluate(()=>window.hingeState);
  const xy=async point=>{
    const s=await read(),box=await page.locator('canvas').boundingBox();
    return {x:box.x+point[0]/s.viewport[0]*box.width,y:box.y+point[1]/s.viewport[1]*box.height};
  };
  const tap=async point=>{
    const p=await xy(point);
    if(info.project.name==='mobile')await page.touchscreen.tap(p.x,p.y);else await page.mouse.click(p.x,p.y);
    await page.waitForTimeout(130);
  };
  const action=async id=>{
    const s=await read();
    if(s.won&&s.screen==='play')await page.waitForFunction(()=>window.hingeState.buttons.some(b=>b.id==='next'));
    await page.waitForFunction(id=>window.hingeState.buttons.some(b=>b.id===id),id);
    await tap((await read()).buttons.find(b=>b.id===id).center);
  };
  const play=async move=>{
    const s=await read(),from=s.state[move[0]].find(c=>c!==move[1]);
    await tap(s.cells[from]);
    await page.waitForFunction(from=>window.hingeState.selected===from,from);
    const choice=(await read()).choices.find(c=>c.piece===move[0]&&c.turn===move[2]);
    expect(choice,'selected moving seed offers the correct landing').toBeTruthy();
    expect(choice.from).toBe(from);
    await tap((await read()).cells[choice.to]);
    await page.waitForFunction(n=>window.hingeState.moves===n&&!window.hingeState.busy,s.moves+1);
  };
  const open=async index=>{
    await action('levels');await page.waitForFunction(()=>window.hingeState.screen==='levels');
    if(!(await read()).buttons.some(b=>b.id==='level_'+index))await action('page');
    await action('level_'+index);
    await page.waitForFunction(i=>window.hingeState.level===i+1&&window.hingeState.screen==='play',index);
  };
  const restart=async()=>{
    const moved=(await read()).moves>0;
    await action('reset');
    if(moved){await page.waitForFunction(()=>window.hingeState.screen==='restart');await action('restart_yes')}
    await page.waitForFunction(()=>window.hingeState.moves===0&&window.hingeState.screen==='play');
  };
  const cdp=info.project.name==='mobile'?await page.context().newCDPSession(page):null;
  const beginDrag=async point=>{
    const p=await xy(point);
    if(cdp)await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:p.x,y:p.y,id:1}]});
    else{await page.mouse.move(p.x,p.y);await page.mouse.down()}
  };
  const moveDrag=async point=>{
    const p=await xy(point);
    if(cdp)await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:p.x,y:p.y,id:1}]});
    else await page.mouse.move(p.x,p.y,{steps:5});
    await page.waitForTimeout(130);
  };
  const endDrag=async()=>{
    if(cdp)await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});else await page.mouse.up();
  };
  const s=await read(),original=JSON.stringify(s.state),from=s.cells[7],pivot=s.cells[3],target=s.cells[2];
  expect(s.coach[0]).toContain('glowing seed');
  expect(s.count).toBe(30);
  await page.screenshot({path:info.outputPath('01-guidance.png')});

  // Direct manipulation starts from the moving seed, with no move committed mid-drag.
  await beginDrag(from);
  const middle=[pivot[0]-(from[1]-pivot[1])*Math.SQRT1_2,pivot[1]+(from[1]-pivot[1])*Math.SQRT1_2];
  await moveDrag(middle);
  await page.waitForFunction(()=>window.hingeState.preview.active);
  expect((await read()).selected).toBe(7);
  expect((await read()).pivot).toBe(3);
  expect((await read()).preview.angle).toBeGreaterThan(0.1);
  expect((await read()).moves).toBe(0);
  expect(JSON.stringify((await read()).state)).toBe(original);
  await page.screenshot({path:info.outputPath('02-drag-preview.png')});
  if(cdp){
    const a=await xy(middle),b=await xy(s.cells[12]);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:a.x,y:a.y,id:1},{x:b.x,y:b.y,id:2}]});
    await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:a.x,y:a.y,id:1}]});
    expect((await read()).moves).toBe(0);
  }
  // An off-board release cancels cleanly.
  await moveDrag([s.viewport[0]-12,s.viewport[1]-12]);
  await endDrag();
  await page.waitForFunction(()=>!window.hingeState.preview.active);
  expect((await read()).moves).toBe(0);
  expect(JSON.stringify((await read()).state)).toBe(original);
  await beginDrag(from);await moveDrag(middle);await moveDrag(target);
  await page.waitForFunction(()=>window.hingeState.preview.to===2);
  await endDrag();
  await page.waitForFunction(()=>window.hingeState.moves===1&&!window.hingeState.busy);
  expect((await read()).roots).toBe(1);
  expect((await read()).particles).toBeGreaterThan(0);
  await page.waitForFunction(()=>window.audioPeak()>0.001,null,{timeout:10000});
  await page.screenshot({path:info.outputPath('03-roots.png')});
  const partial=JSON.stringify((await read()).state);
  await page.reload();await ready();
  expect((await read()).moves).toBe(1);
  expect((await read()).history).toBe(1);
  expect(JSON.stringify((await read()).state)).toBe(partial);
  await tap((await read()).cells[2]);
  expect((await read()).message).toContain('has roots');
  expect((await read()).choices).toEqual([]);
  await action('undo');
  await page.waitForFunction(()=>window.hingeState.moves===0);
  expect(JSON.stringify((await read()).state)).toBe(original);
  expect((await read()).roots).toBe(0);

  await action('hint');expect((await read()).moves).toBe(0);expect((await read()).selected).toBe(7);
  for(const move of campaign[0].solution)await play(move);
  await page.waitForFunction(()=>window.hingeState.won);
  await page.screenshot({path:info.outputPath('04-petals-opening.png')});
  await page.waitForFunction(()=>window.hingeState.buttons.some(b=>b.id==='next'));
  expect((await read()).buttons.some(b=>['undo','hint','reset'].includes(b.id))).toBe(false);
  const next=(await read()).buttons.find(b=>b.id==='next'),box=await page.locator('canvas').boundingBox();
  expect(next.size[1]/(await read()).viewport[1]*box.height).toBeGreaterThanOrEqual(48);
  await page.screenshot({path:info.outputPath('05-bloom.png')});
  await action('next');await page.waitForFunction(()=>window.hingeState.level===2);
  await play(campaign[1].solution[0]);
  const second=JSON.stringify((await read()).state);
  await open(9);await open(1);
  expect(JSON.stringify((await read()).state)).toBe(second);
  expect((await read()).moves).toBe(1);
  await action('reset');await page.waitForFunction(()=>window.hingeState.screen==='restart');
  await action('close');expect((await read()).moves).toBe(1);
  await restart();

  await open(audit.dead_end_fixture.level-1);
  for(const move of audit.dead_end_fixture.moves)await play(move);
  await page.waitForFunction(()=>window.hingeState.stuck);
  expect((await read()).won).toBe(false);
  await page.screenshot({path:info.outputPath('06-recovery.png')});
  await action('recover');await page.waitForFunction(()=>!window.hingeState.stuck);
  expect((await read()).moves).toBeLessThan(audit.dead_end_fixture.moves.length);
  await restart();
  for(const move of campaign[audit.dead_end_fixture.level-1].solution)await play(move);
  for(const index of [18,29]){
    await open(index);
    await page.screenshot({path:info.outputPath('garden-'+(index+1)+'.png')});
    for(const move of campaign[index].solution)await play(move);
    await page.waitForFunction(()=>window.hingeState.won);
  }
  await action('next');
  await page.waitForFunction(()=>window.hingeState.level===2);
  expect((await read()).screen).toBe('play'); // Garden 30 is not the ending if others remain unfinished.

  await action('settings');await action('music');await action('sound');await action('motion');await action('guidance');
  await page.waitForTimeout(450);await page.waitForFunction(()=>window.audioPeak()<0.00001);
  await page.screenshot({path:info.outputPath('07-settings.png')});
  await action('close');await open(0);
  await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowDown');await page.keyboard.press('Enter');
  await page.waitForFunction(()=>window.hingeState.selected===7);
  await page.keyboard.press('ArrowUp');await page.keyboard.press('ArrowLeft');await page.keyboard.press('Enter');
  await page.waitForFunction(()=>window.hingeState.moves===1&&!window.hingeState.busy);
  expect((await read()).particles).toBe(0);
  await page.reload();await ready();
  expect((await read()).moves).toBe(1);expect((await read()).motion).toBe(true);expect((await read()).guidance).toBe(false);
  expect((await read()).music).toBe(false);expect((await read()).sound).toBe(false);
  await page.keyboard.press('z');await page.waitForFunction(()=>window.hingeState.moves===0);
  if(info.project.name==='mobile'){
    await page.setViewportSize({width:360,height:640});
    await page.waitForFunction(()=>Math.abs(window.hingeState.viewport[0]/window.hingeState.viewport[1]-360/640)<0.001);
    await action('settings');
    await page.waitForFunction(()=>window.hingeState.screen==='settings'&&window.hingeState.buttons.some(b=>b.id==='guidance'));
    const state=await read(),canvas=await page.locator('canvas').boundingBox();
    for(const button of state.buttons){
      expect(button.size[1]/state.viewport[1]*canvas.height).toBeGreaterThanOrEqual(48);
      expect(button.center[1]+button.size[1]/2).toBeLessThanOrEqual(state.viewport[1]);
    }
    await page.screenshot({path:info.outputPath('08-small-phone.png')});
  }
  expect(errors).toEqual([]);
});

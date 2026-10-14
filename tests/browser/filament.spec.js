const {test,expect}=require('@playwright/test');
const levels=require('../../data/levels.json');

test('Filament: real dragging, overlap recovery, anchors, undo, keyboard and completion',async({page},info)=>{
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(/SCRIPT ERROR|Parse Error|ERROR:/.test(m.text()))errors.push(m.text());});
  await page.goto('/');
  await page.waitForFunction(()=>window.filamentReady===true,null,{timeout:90000});
  await expect(page.locator('#loading')).toBeHidden();
  const state=page.locator('#game-state');
  await expect(state).toHaveAttribute('data-game','filament');
  const vp=page.viewportSize(),scale=Math.min(vp.width/720,vp.height/1000);
  const ox=(vp.width-720*scale)/2,oy=(vp.height-1000*scale)/2;
  const point=(x,y)=>({x:ox+x*scale,y:oy+y*scale});
  const mobile=info.project.name==='mobile';
  const cdp=mobile?await page.context().newCDPSession(page):null;
  async function tap(x,y){const p=point(x,y);if(mobile)await page.touchscreen.tap(p.x,p.y);else await page.mouse.click(p.x,p.y);await page.waitForTimeout(180);}
  async function coords(){return JSON.parse(await state.getAttribute('data-points'));}
  async function start(p){
    const v=point(...p);
    if(mobile)await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:v.x,y:v.y,id:1}]});
    else {await page.mouse.move(v.x,v.y);await page.mouse.down();}
    await page.waitForTimeout(120);
  }
  async function finish(){
    if(mobile)await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});else await page.mouse.up();
    await expect(state).toHaveAttribute('data-dragging','-1');
  }
  async function drag(index,to,shot){
    const before=await coords(),from=before[index];
    for(let tries=0;tries<before.length;tries++){
      await start(from);
      if(Number(await state.getAttribute('data-dragging'))===index)break;
      await finish();
    }
    await expect(state).toHaveAttribute('data-dragging',String(index));
    for(let i=1;i<=8;i++){
      const p=point(from[0]+(to[0]-from[0])*i/8,from[1]+(to[1]-from[1])*i/8);
      if(mobile)await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:p.x,y:p.y,id:1}]});
      else await page.mouse.move(p.x,p.y);
      await page.waitForTimeout(35);
    }
    // Clear geometry while held must not end input or award a move prematurely.
    await expect(state).toHaveAttribute('data-screen','play');
    if(shot)await page.screenshot({path:info.outputPath(shot)});
    await finish();
    const after=await coords();
    expect(Math.abs(after[index][0]-to[0])).toBeLessThan(2);
    expect(Math.abs(after[index][1]-to[1])).toBeLessThan(2);
  }
  await expect(state).toHaveAttribute('data-tangles','1');
  await page.waitForTimeout(500);
  await page.screenshot({path:info.outputPath('filament-first.png')});
  const animatedA=await page.screenshot();
  await page.waitForTimeout(450);
  const animatedB=await page.screenshot();
  expect(animatedA.equals(animatedB)).toBeFalsy();
  const initial=await coords();
  await drag(0,[360,520],'filament-drag.png');
  await expect(state).toHaveAttribute('data-moves','1');
  await tap(190,894);
  expect(await coords()).toEqual(initial);
  await expect(state).toHaveAttribute('data-moves','0');
  // Coincident knots cannot fake a win, and both remain reachable.
  await drag(1,initial[2]);
  await expect(state).toHaveAttribute('data-screen','play');
  expect(Number(await state.getAttribute('data-tangles'))).toBeGreaterThan(0);
  await drag(2,levels[0].solution[2]);
  await expect(state).toHaveAttribute('data-screen','won');
  await expect(state).toHaveAttribute('data-tangles','0');
  await expect(state).toHaveAttribute('data-moves','2');
  await page.screenshot({path:info.outputPath('filament-won.png')});
  await tap(360,893);
  await expect(state).toHaveAttribute('data-level','2');
  // Hints mark a destination but never move the web.
  const preHint=await coords();await tap(360,894);
  expect(await coords()).toEqual(preHint);
  await expect(state).toHaveAttribute('data-hints','1');
  await tap(530,894);
  await expect(state).toHaveAttribute('data-hints','0');
  if(!mobile){
    const original=await coords();
    await page.keyboard.press('Tab');
    await expect(state).toHaveAttribute('data-focus','0');
    await page.keyboard.press('ArrowRight');await page.keyboard.press('Enter');
    await expect(state).toHaveAttribute('data-moves','1');
    const changed=await coords();expect(changed[0][0]).toBeCloseTo(original[0][0]+20,1);
    await page.keyboard.press('u');expect(await coords()).toEqual(original);
  }
  await tap(641,52);
  await expect(state).toHaveAttribute('data-screen','help');
  await page.screenshot({path:info.outputPath('filament-help.png')});
  await tap(190,734);await tap(520,734);
  await expect(state).toHaveAttribute('data-sound','off');
  await expect(state).toHaveAttribute('data-motion','calm');
  await tap(360,883);
  await tap(540,52);
  await expect(state).toHaveAttribute('data-screen','levels');
  await page.screenshot({path:info.outputPath('filament-webs.png')});
  await tap(523,760);
  await expect(state).toHaveAttribute('data-level','12');
  const anchor=levels[11].anchors[0],p=(await coords())[anchor];
  await start(p);
  await expect(state).toHaveAttribute('data-dragging','-1');
  await finish();
  expect((await coords())[anchor]).toEqual(p);
  await expect(state).toHaveAttribute('data-moves','0');
  await page.screenshot({path:info.outputPath('filament-intricate.png')});
  // Reload checks real browser persistence, not merely an in-memory flag.
  await page.reload();
  await page.waitForFunction(()=>window.filamentReady===true,null,{timeout:90000});
  await expect(state).toHaveAttribute('data-level','12');
  await expect(state).toHaveAttribute('data-completed','1');
  await expect(state).toHaveAttribute('data-sound','off');
  await expect(state).toHaveAttribute('data-motion','calm');
  await expect(page.locator('#archive-link')).toHaveAttribute('href','experiments/');
  expect(errors).toEqual([]);
});

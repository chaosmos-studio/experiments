const {test,expect}=require('@playwright/test');
const levels=require('../../data/levels.json');

test('Filament: real dragging, overlap recovery, anchors, undo, keyboard and completion',async({page},info)=>{
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(/SCRIPT ERROR|Parse Error|ERROR:/.test(m.text()))errors.push(m.text());});
  // Observe real PCM without changing the game's output route.
  await page.addInitScript(()=>{
    window.__audioProbes=[];
    const Native=window.AudioContext||window.webkitAudioContext;
    if(!Native)return;
    const observed=new WeakMap();
    const Wrapped=class extends Native{
      constructor(...args){super(...args);const analyser=this.createAnalyser();analyser.fftSize=2048;observed.set(this,analyser);window.__audioProbes.push(analyser);}
    };
    const connect=AudioNode.prototype.connect;
    AudioNode.prototype.connect=function(destination,...args){
      const analyser=observed.get(this.context);
      if(analyser&&destination===this.context.destination)connect.call(this,analyser);
      return connect.call(this,destination,...args);
    };
    window.AudioContext=Wrapped;if(window.webkitAudioContext)window.webkitAudioContext=Wrapped;
    window.__audioPeak=()=>Math.max(0,...window.__audioProbes.map(a=>{const samples=new Float32Array(a.fftSize);a.getFloatTimeDomainData(samples);return Math.max(...samples.map(Math.abs));}));
  });
  await page.goto('/');
  await page.waitForFunction(()=>window.filamentReady===true,null,{timeout:90000});
  await expect(page.locator('#loading')).toBeHidden();
  const state=page.locator('#game-state');
  await expect(state).toHaveAttribute('data-game','filament');
  const vp=page.viewportSize(),scale=Math.min(vp.width/720,vp.height/1000);
  const h=Math.max(1000,Math.min(1440,vp.height/scale)),g=h>1100?1.1:1;
  const ox=(vp.width-720*scale)/2,oy=(vp.height-h*scale)/2;
  const uiPoint=(x,y)=>({x:ox+x*scale,y:oy+y*scale});
  const point=(x,y)=>uiPoint(360+(x-360)*g,520+(h-1000)/2+(y-520)*g);
  const mobile=info.project.name==='mobile';
  const cdp=mobile?await page.context().newCDPSession(page):null;
  async function tap(x,y){const p=uiPoint(x,y);if(mobile)await page.touchscreen.tap(p.x,p.y);else await page.mouse.click(p.x,p.y);await page.waitForTimeout(180);}
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
  await expect(state).toHaveAttribute('data-theme','light');
  await expect(state).toHaveAttribute('data-music','on');
  await expect(state).toHaveAttribute('data-audio-started','false');
  await expect(page.locator('html')).toHaveAttribute('data-theme','light');
  await page.waitForTimeout(500);
  await page.screenshot({path:info.outputPath('filament-first.png')});
  const animatedA=await page.screenshot();
  await page.waitForTimeout(450);
  const animatedB=await page.screenshot();
  expect(animatedA.equals(animatedB)).toBeFalsy();
  const initial=await coords();
  await drag(0,[360,520],'filament-drag.png');
  await expect(state).toHaveAttribute('data-moves','1');
  await tap(117,h-93);
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
  await tap(455,h-96);
  await expect(state).toHaveAttribute('data-level','2');
  // Hints mark a destination but never move the web.
  const preHint=await coords();await tap(279,h-93);
  expect(await coords()).toEqual(preHint);
  await expect(state).toHaveAttribute('data-hints','1');
  await tap(441,h-93);
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
  await expect(state).toHaveAttribute('data-audio-started','true');
  await expect(state).toHaveAttribute('data-audio-playing','true');
  await page.waitForTimeout(800); // Let the last short effect finish.
  await expect.poll(()=>page.evaluate(()=>window.__audioPeak())).toBeGreaterThan(0.0001);
  await tap(636,52);
  await expect(state).toHaveAttribute('data-screen','settings');
  await page.screenshot({path:info.outputPath('filament-settings-light.png')});
  await tap(570,527); // Effects off, music stays on.
  await expect(state).toHaveAttribute('data-sound','off');
  await expect(state).toHaveAttribute('data-music','on');
  await expect.poll(()=>page.evaluate(()=>window.__audioPeak())).toBeGreaterThan(0.0001);
  await tap(570,310); // Music off.
  await expect(state).toHaveAttribute('data-music','off');
  await page.waitForTimeout(1100);
  expect(await page.evaluate(()=>window.__audioPeak())).toBeLessThan(0.0001);
  await tap(336,418);
  await expect(state).toHaveAttribute('data-music-volume','40');
  await tap(570,741);
  await expect(state).toHaveAttribute('data-motion','calm');
  await tap(570,634);
  await expect(state).toHaveAttribute('data-theme','dark');
  await expect(page.locator('html')).toHaveAttribute('data-theme','dark');
  await page.screenshot({path:info.outputPath('filament-settings-dark.png')});
  await tap(190,h-80);
  await expect(state).toHaveAttribute('data-screen','help');
  await page.screenshot({path:info.outputPath('filament-help.png')});
  await tap(360,h-80);
  await expect(state).toHaveAttribute('data-screen','settings');
  await tap(520,h-80);
  await expect(state).toHaveAttribute('data-screen','play');
  await page.screenshot({path:info.outputPath('filament-dark.png')});
  await tap(603,h-93);
  await expect(state).toHaveAttribute('data-screen','levels');
  await page.screenshot({path:info.outputPath('filament-webs.png')});
  await tap(523,250+5.5*((h-340)/6)-6);
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
  await expect(state).toHaveAttribute('data-theme','dark');
  await expect(state).toHaveAttribute('data-music','off');
  await expect(state).toHaveAttribute('data-music-volume','40');
  await expect(state).toHaveAttribute('data-audio-started','false');
  await tap(636,52);await tap(570,634);await tap(520,h-80);
  await expect(state).toHaveAttribute('data-theme','light');
  await page.screenshot({path:info.outputPath('filament-intricate-light.png')});
  await tap(603,h-93);
  await page.screenshot({path:info.outputPath('filament-webs-light.png')});
  await expect(page.locator('#archive-link')).toHaveAttribute('href','experiments/');
  expect(errors).toEqual([]);
});

const {test,expect}=require('@playwright/test');
const levels=require('../../data/levels.json');
const shapes=require('../../data/shapes.json');

test('Tessera: placement, real loss, undo, keyboard, queue and completion',async({page},info)=>{
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(/SCRIPT ERROR|Parse Error|ERROR:/.test(m.text()))errors.push(m.text());});
  await page.goto('/');
  await page.waitForFunction(()=>window.tesseraReady===true,null,{timeout:90000});
  await expect(page.locator('#loading')).toBeHidden();
  const state=page.locator('#game-state');
  await expect(state).toHaveAttribute('data-game','tessera');
  const vp=page.viewportSize(),scale=Math.min(vp.width/720,vp.height/1000);
  const ox=(vp.width-720*scale)/2,oy=(vp.height-1000*scale)/2;
  const point=(x,y)=>({x:ox+x*scale,y:oy+y*scale});
  async function tap(x,y){const p=point(x,y);if(info.project.name==='mobile')await page.touchscreen.tap(p.x,p.y);else await page.mouse.click(p.x,p.y);await page.waitForTimeout(300);}
  async function assertMove(action, input='tap'){
    const [i,x,y]=action;
    let board=BigInt(await state.getAttribute('data-board'));
    const beforeUsed=Number(await state.getAttribute('data-used'));
    const beforeLines=Number(await state.getAttribute('data-lines'));
    for(const [dx,dy] of shapes[levels[0].pieces[i]])board|=1n<<BigInt((y+dy)*6+x+dx);
    let clear=0n,lines=0;
    for(let axis=0;axis<2;axis++)for(let k=0;k<6;k++){
      let mask=0n;for(let j=0;j<6;j++)mask|=1n<<BigInt(axis?k+j*6:k*6+j);
      if((board&mask)===mask){clear|=mask;lines++;}
    }
    if(input==='drag'){
      const a=point(148+(i%3)*212,837),b=point(102+x*86+43,210+y*86+43);
      await page.mouse.move(a.x,a.y);await page.mouse.down();await page.waitForTimeout(150);
      await page.mouse.move(b.x,b.y,{steps:8});await page.waitForTimeout(300);
      await page.screenshot({path:info.outputPath('placement-preview.png')});
      await page.mouse.up();
    }else if(input==='keyboard'){
      await page.keyboard.press(String(i%3+1));
      for(let j=0;j<6;j++){await page.keyboard.press('ArrowLeft');await page.keyboard.press('ArrowUp');}
      for(let j=0;j<x;j++)await page.keyboard.press('ArrowRight');
      for(let j=0;j<y;j++)await page.keyboard.press('ArrowDown');
      await page.keyboard.press('Enter');
    }else{
      await tap(148+(i%3)*212,837);
      await expect(state).toHaveAttribute('data-selected',String(i));
      await tap(102+x*86+43,210+y*86+43);
    }
    await expect(state).toHaveAttribute('data-used',String(beforeUsed|(1<<i)));
    await expect(state).toHaveAttribute('data-board',String(board&~clear));
    await expect(state).toHaveAttribute('data-lines',String(beforeLines+lines));
  }
  await page.screenshot({path:info.outputPath('tessera-first.png')});
  // Invalid placement consumes nothing.
  await tap(148,837);await tap(102+5*86+43,210+5*86+43);
  await expect(state).toHaveAttribute('data-used','0');
  await assertMove(levels[0].solution[0],info.project.name==='desktop'?'drag':'tap');
  await tap(144,942);
  await expect(state).toHaveAttribute('data-board',levels[0].board);
  await expect(state).toHaveAttribute('data-used','0');
  for(const action of levels[0].failure_route)await assertMove(action);
  await expect(state).toHaveAttribute('data-screen','lost');
  await page.screenshot({path:info.outputPath('tessera-lost.png')});
  await tap(360,553);
  await expect(state).toHaveAttribute('data-screen','play');
  await tap(576,942);
  await tap(570,65);
  await expect(state).toHaveAttribute('data-screen','queue');
  await expect(state).toHaveAttribute('data-hints','0');
  await page.screenshot({path:info.outputPath('tessera-queue.png')});
  await tap(360,756);
  for(let n=0;n<levels[0].solution.length;n++){
    await assertMove(levels[0].solution[n],n===0&&info.project.name==='desktop'?'keyboard':'tap');
  }
  await expect(state).toHaveAttribute('data-screen','won');
  await expect(state).toHaveAttribute('data-undos','0');
  await expect(state).toHaveAttribute('data-hints','0');
  await page.screenshot({path:info.outputPath('tessera-won.png')});
  await tap(360,553);
  await expect(state).toHaveAttribute('data-level','2');
  await tap(651,65);
  await page.screenshot({path:info.outputPath('tessera-help.png')});
  await tap(540,750);
  await tap(461,65);await tap(580,564);
  await expect(state).toHaveAttribute('data-level','18');
  await page.screenshot({path:info.outputPath('tessera-master.png')});
  await expect(page.locator('#archive-link')).toHaveAttribute('href','experiments/rivet/');
  expect(errors).toEqual([]);
});

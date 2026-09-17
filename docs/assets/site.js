(()=>{
'use strict';
const $=id=>document.getElementById(id),all=s=>Array.from(document.querySelectorAll(s));
const config=window.GEOPRISM||{};let repo=config.repositoryUrl||'';
const host=location.hostname.match(/^([a-z0-9-]+)\.github\.io$/i),part=location.pathname.split('/').filter(Boolean)[0];
if(!repo&&host)repo=`https://github.com/${host[1]}/${part&&!part.includes('.')?part:host[1]+'.github.io'}`;
function validUrl(value){try{const u=new URL(value);return u.protocol==='https:'?u.href:'';}catch{return '';}}
for(const [selector,value]of [['[data-repository]',repo],['[data-app]',config.appUrl]])for(const a of all(selector)){const url=validUrl(value);if(url){a.href=url;a.hidden=false;}}
for(const button of all('[data-copy]'))button.addEventListener('click',async()=>{const block=$(button.dataset.copy);try{await navigator.clipboard.writeText(block.textContent);button.textContent='Copied';}catch{const range=document.createRange();range.selectNodeContents(block);const selection=window.getSelection();selection.removeAllRanges();selection.addRange(range);button.textContent='Selected';}setTimeout(()=>button.textContent='Copy',2200);});
const canvas=$('scatter-canvas');if(!canvas)return;
const M=window.GEOPrismMath,ctx=canvas.getContext('2d');
if(!ctx||!M){$('explorer-status').textContent='Explorer unavailable. Please use the R app.';return;}
const demo=M.createDemo(),colors=['#218877','#416dd1','#c27435'],groups=['Group A','Group B','Group C'];
const reducedMotion=window.matchMedia('(prefers-reduced-motion: reduce)');
const state={view:'scatter',mode:'3d',yaw:-.55,pitch:.28,zoom:1,size:5,grid:true,color:'group',visible:[true,true,true],selected:0,sort:'id',ascending:true,query:'',rotate:false,scale:false};
let result,extent,projected=[],width=1,height=1,raf=0,lastFrame=0,inView=true,hovered=-1,velocity={x:0,y:0},drag=null;
const pointers=new Map();let pinchDistance=0;
const valueMin=Math.min(...demo.samples.flatMap(s=>s.values)),valueMax=Math.max(...demo.samples.flatMap(s=>s.values));
const visibleIndices=()=>demo.samples.map((_,i)=>i).filter(i=>state.visible[demo.samples[i].group]);
const text=(id,value)=>{if($(id))$(id).textContent=value;};
function recalculate(){result=M.pca(demo.samples.map(s=>s.values),state.scale);extent=Math.max(...result.scores.flatMap(row=>row.map(Math.abs)))*1.12;}
function project(point){return M.project(point,state,width,height);}
function scorePoint(i){return result.scores[i].map(v=>v/extent*1.7);}
function line(a,b,color='#e4e9ef',dash=[]){const p=project(a),q=project(b);ctx.beginPath();ctx.setLineDash(dash);ctx.moveTo(p.x,p.y);ctx.lineTo(q.x,q.y);ctx.strokeStyle=color;ctx.lineWidth=1;ctx.stroke();ctx.setLineDash([]);}
function label(point,value,color='#738398'){const p=project(point);ctx.font='10px Consolas,monospace';ctx.fillStyle=color;ctx.textAlign='center';ctx.fillText(value,p.x,p.y);}
function draw(){
 ctx.clearRect(0,0,width,height);ctx.fillStyle='#ffffff';ctx.fillRect(0,0,width,height);
 const b=1.75;
 if(state.mode==='3d'){
  if(state.grid){for(let i=-2;i<=2;i++){const t=i*b/2;line([-b,-b,t],[b,-b,t]);line([t,-b,-b],[t,-b,b]);}line([-b,-b,-b],[-b,b,-b],'#e0e6ee');line([-b,b,-b],[b,b,-b],'#edf0f4',[3,4]);line([b,b,-b],[b,-b,-b],'#edf0f4',[3,4]);}
  line([-b,-b,-b],[b,-b,-b],'#c5ceda');line([-b,-b,-b],[-b,b,-b],'#c5ceda');line([-b,-b,-b],[-b,-b,b],'#c5ceda');
  label([b+.04,-b-.18,-b],`PC 1 · ${result.variance[0].toFixed(1)}%`);
  label([-b-.02,b+.13,-b],`PC 2 · ${result.variance[1].toFixed(1)}%`);
  label([-b,-b-.2,b+.12],`PC 3 · ${result.variance[2].toFixed(1)}%`);
 }else{
  if(state.grid)for(let i=-2;i<=2;i++){const t=i*b/2;line([-b,t,0],[b,t,0]);line([t,-b,0],[t,b,0]);}
  line([-b,0,0],[b,0,0],'#c7d1df');line([0,-b,0],[0,b,0],'#c7d1df');
  label([0,-b-.3,0],`PC 1 · ${result.variance[0].toFixed(1)}%`);label([0,b+.16,0],`PC 2 · ${result.variance[1].toFixed(1)}%`);
 }
 projected=visibleIndices().map(i=>({...project(scorePoint(i)),i})).sort((a,b)=>a.depth-b.depth);
 for(const p of projected){const sample=demo.samples[p.i],color=colors[state.color==='group'?sample.group:sample.batch],radius=state.size*Math.max(.65,Math.min(1.45,p.scale));
  if(p.i===state.selected||p.i===hovered){ctx.beginPath();ctx.arc(p.x,p.y,radius+4,0,Math.PI*2);ctx.strokeStyle=p.i===state.selected?color:'#9dabbc';ctx.lineWidth=1.3;ctx.stroke();}
  const light=ctx.createRadialGradient(p.x-radius*.28,p.y-radius*.32,.4,p.x,p.y,radius);light.addColorStop(0,'#c7ddf0');light.addColorStop(.28,color);light.addColorStop(1,color);
  ctx.beginPath();ctx.arc(p.x,p.y,radius,0,Math.PI*2);ctx.fillStyle=state.mode==='3d'?light:color;ctx.globalAlpha=.88;ctx.fill();ctx.globalAlpha=1;ctx.strokeStyle='white';ctx.lineWidth=.8;ctx.stroke();
 }
 if(projected.length){const selected=projected.find(p=>p.i===state.selected);if(selected){ctx.font='10px Consolas,monospace';ctx.textAlign='left';const title=demo.samples[state.selected].id,x=Math.min(width-85,Math.max(8,selected.x+12)),y=Math.max(17,selected.y-11);ctx.fillStyle='#fff';ctx.fillRect(x-3,y-11,79,15);ctx.fillStyle='#4b5f7c';ctx.fillText(title,x,y);}}
}
function frame(time){raf=0;const dt=Math.min(40,time-(lastFrame||time));lastFrame=time;
 if(state.view==='scatter'&&!document.hidden&&inView){if(state.mode==='3d'){if(state.rotate)state.yaw+=dt*.00017;if(!drag&&!reducedMotion.matches){state.yaw+=velocity.x;state.pitch=Math.max(-1.1,Math.min(1.1,state.pitch+velocity.y));velocity.x*=.9;velocity.y*=.9;}}draw();
 if((state.rotate||Math.abs(velocity.x)+Math.abs(velocity.y)>.0003)&&state.mode==='3d')raf=requestAnimationFrame(frame);}
}
function schedule(){if(!raf)raf=requestAnimationFrame(frame);}
function resize(){const box=canvas.getBoundingClientRect();if(!box.width||!box.height)return;width=box.width;height=box.height;const ratio=Math.min(window.devicePixelRatio||1,2);canvas.width=Math.round(width*ratio);canvas.height=Math.round(height*ratio);ctx.setTransform(ratio,0,0,ratio,0,0);schedule();}
function renderLegend(){const names=state.color==='group'?groups:['Batch 1','Batch 2'];$('plot-legend').replaceChildren(...names.map((name,i)=>{const span=document.createElement('span'),dot=document.createElement('i');dot.className='dot';dot.style.background=colors[i];span.append(dot,document.createTextNode(name));return span;}));}
function inspector(){const s=demo.samples[state.selected],visible=visibleIndices(),position=visible.indexOf(state.selected);text('selected-id',s.id);text('selected-group',`${groups[s.group]} · synthetic sample`);text('selected-batch',`Batch ${s.batch+1}`);for(let k=0;k<3;k++)text(`selected-pc${k+1}`,result.scores[state.selected][k].toFixed(3));$('selection-status').hidden=position>=0;text('sample-position',position>=0?`${position+1} of ${visible.length}`:'No visible sample');$('previous-sample').disabled=$('next-sample').disabled=!visible.length;
 const heat=$('feature-profile');heat.setAttribute('aria-label',`${s.id}, 36 synthetic feature values from ${Math.min(...s.values).toFixed(2)} to ${Math.max(...s.values).toFixed(2)}`);heat.replaceChildren(...s.values.map((v,j)=>{const t=(v-valueMin)/(valueMax-valueMin),node=document.createElement('span');node.style.background=`rgb(${Math.round(236-187*t)},${Math.round(241-139*t)},${Math.round(246-64*t)})`;node.title=`${demo.genes[j]}: ${v.toFixed(3)}`;return node;}));
}
function selectSample(index){state.selected=index;inspector();renderTable();schedule();text('explorer-status',`Inspecting ${demo.samples[index].id}`);}
function renderTable(){const focusedId=document.activeElement?.dataset?.sampleId;let indices=visibleIndices().filter(i=>{const s=demo.samples[i];return`${s.id} ${groups[s.group]} Batch ${s.batch+1}`.toLowerCase().includes(state.query);});
 const sortValue=i=>state.sort==='id'?demo.samples[i].id:state.sort==='group'?demo.samples[i].group:result.scores[i][Number(state.sort.slice(-1))-1];
 indices.sort((a,b)=>{const x=sortValue(a),y=sortValue(b);return(typeof x==='string'?x.localeCompare(y):x-y)*(state.ascending?1:-1);});
 const fragment=document.createDocumentFragment();for(const i of indices){const s=demo.samples[i],tr=document.createElement('tr');if(i===state.selected)tr.className='selected';const td=document.createElement('td'),button=document.createElement('button');button.textContent=s.id;button.dataset.sampleId=s.id;button.setAttribute('aria-label',`Inspect ${s.id}`);button.addEventListener('click',()=>selectSample(i));td.append(button);tr.append(td);for(const value of[groups[s.group],`Batch ${s.batch+1}`,...result.scores[i].map(v=>v.toFixed(3))]){const cell=document.createElement('td');cell.textContent=value;tr.append(cell);}fragment.append(tr);}
 if(!indices.length){const tr=document.createElement('tr'),td=document.createElement('td');td.colSpan=6;td.textContent='No samples match these filters.';tr.append(td);fragment.append(tr);}
 $('sample-rows').replaceChildren(fragment);if(focusedId){const restored=Array.from($('sample-rows').querySelectorAll('button')).find(b=>b.dataset.sampleId===focusedId);if(restored)restored.focus({preventScroll:true});}text('table-count',`${indices.length} samples`);
 for(const button of all('[data-sort]'))button.parentElement.setAttribute('aria-sort',button.dataset.sort===state.sort?(state.ascending?'ascending':'descending'):'none');
}
function renderVariance(){const fragment=document.createDocumentFragment();result.variance.slice(0,6).forEach((v,i)=>{const row=document.createElement('div');row.className='variance-row';const title=document.createElement('span');title.textContent=`PC ${i+1}`;const track=document.createElement('div');track.className='variance-track';const bar=document.createElement('div');bar.className='variance-bar';bar.style.width=`${v}%`;track.append(bar);const value=document.createElement('span');value.className='variance-number';value.textContent=`${v.toFixed(1)}%`;row.append(title,track,value);fragment.append(row);});$('variance-chart').replaceChildren(fragment);text('variance-summary',`PC 1–3 together explain ${result.variance.slice(0,3).reduce((a,b)=>a+b,0).toFixed(1)}% of the synthetic dataset's variance.`);}
function refresh(){const visible=visibleIndices();text('visible-count',`${visible.length} / 72 samples`);text('pca-mode',state.scale?'Centered · scaled':'Centered · unscaled');$('empty-plot').hidden=visible.length>0;renderLegend();inspector();renderTable();renderVariance();schedule();}
function setView(view){state.view=view;velocity={x:0,y:0};for(const button of all('[data-view]')){const active=button.dataset.view===view;button.setAttribute('aria-selected',String(active));button.tabIndex=active?0:-1;$(`panel-${button.dataset.view}`).hidden=!active;}if(view==='scatter')resize();}
for(const button of all('[data-view]')){button.addEventListener('click',()=>setView(button.dataset.view));button.addEventListener('keydown',e=>{const tabs=all('[data-view]'),i=tabs.indexOf(button);let next;if(e.key==='ArrowRight')next=(i+1)%tabs.length;if(e.key==='ArrowLeft')next=(i+tabs.length-1)%tabs.length;if(e.key==='Home')next=0;if(e.key==='End')next=tabs.length-1;if(next!==undefined){e.preventDefault();setView(tabs[next].dataset.view);tabs[next].focus();}});}
function stopRotation(){state.rotate=false;velocity={x:0,y:0};$('auto-rotate').setAttribute('aria-pressed','false');text('auto-rotate','Rotate view');}
for(const button of all('[data-projection]'))button.addEventListener('click',()=>{state.mode=button.dataset.projection;if(state.mode==='2d')stopRotation();for(const b of all('[data-projection]'))b.setAttribute('aria-pressed',String(b===button));$('auto-rotate').disabled=state.mode==='2d';canvas.setAttribute('aria-label',`Interactive ${state.mode.toUpperCase()} PCA of synthetic samples`);text('canvas-help',state.mode==='3d'?'Drag to rotate · arrow keys to orbit · + / − to zoom':'PC 1 × PC 2 · select a point to inspect · + / − to zoom');schedule();});
$('auto-rotate').addEventListener('click',()=>{state.rotate=!state.rotate;$('auto-rotate').setAttribute('aria-pressed',String(state.rotate));text('auto-rotate',state.rotate?'Pause rotation':'Rotate view');velocity={x:0,y:0};schedule();});
$('color-by').addEventListener('change',e=>{state.color=e.target.value;renderLegend();schedule();});
for(const input of all('[data-group]'))input.addEventListener('change',()=>{state.visible[Number(input.dataset.group)]=input.checked;const visible=visibleIndices();if(!visible.includes(state.selected)&&visible.length)state.selected=visible[0];refresh();text('explorer-status','Display filters updated; PCA unchanged');});
$('point-size').addEventListener('input',e=>{state.size=Number(e.target.value);text('point-size-value',state.size);schedule();});
function setZoom(value){state.zoom=Math.max(.6,Math.min(1.75,value));$('zoom').value=String(Math.round(state.zoom*100));text('zoom-value',`${Math.round(state.zoom*100)}%`);schedule();}
$('zoom').addEventListener('input',e=>setZoom(Number(e.target.value)/100));$('show-grid').addEventListener('change',e=>{state.grid=e.target.checked;schedule();});
$('scale-features').addEventListener('change',e=>{state.scale=e.target.checked;try{recalculate();refresh();text('explorer-status','PCA recalculated');}catch(error){text('explorer-status',error.message);}});
$('sample-search').addEventListener('input',e=>{state.query=e.target.value.trim().toLowerCase();renderTable();});
for(const b of all('[data-sort]'))b.addEventListener('click',()=>{if(state.sort===b.dataset.sort)state.ascending=!state.ascending;else{state.sort=b.dataset.sort;state.ascending=true;}renderTable();});
for(const[id,delta]of[['previous-sample',-1],['next-sample',1]])$(id).addEventListener('click',()=>{const visible=visibleIndices();if(visible.length)selectSample(visible[(visible.indexOf(state.selected)+delta+visible.length)%visible.length]);});
$('reset-view').addEventListener('click',()=>{stopRotation();Object.assign(state,{view:'scatter',mode:'3d',yaw:-.55,pitch:.28,zoom:1,size:5,grid:true,color:'group',visible:[true,true,true],selected:0,sort:'id',ascending:true,query:'',scale:false});$('color-by').value='group';$('point-size').value='5';text('point-size-value','5');$('zoom').value='100';text('zoom-value','100%');$('show-grid').checked=true;$('scale-features').checked=false;$('sample-search').value='';for(const input of all('[data-group]'))input.checked=true;for(const b of all('[data-projection]'))b.setAttribute('aria-pressed',String(b.dataset.projection==='3d'));$('auto-rotate').disabled=false;canvas.setAttribute('aria-label','Interactive 3D PCA of 72 synthetic samples');text('canvas-help','Drag to rotate · arrow keys to orbit · + / − to zoom');recalculate();setView('scatter');refresh();text('explorer-status','Explorer reset');});
const position=e=>{const r=canvas.getBoundingClientRect();return{x:e.clientX-r.left,y:e.clientY-r.top};};
canvas.addEventListener('pointerdown',e=>{if(e.pointerType==='mouse'&&e.button!==0)return;canvas.focus({preventScroll:true});canvas.setPointerCapture(e.pointerId);pointers.set(e.pointerId,position(e));stopRotation();drag={...position(e),start:position(e),moved:false,pinched:false};if(pointers.size===2){const p=[...pointers.values()];pinchDistance=Math.hypot(p[0].x-p[1].x,p[0].y-p[1].y);drag.pinched=true;} $('sample-tooltip').hidden=true;});
canvas.addEventListener('pointermove',e=>{const pos=position(e);if(pointers.has(e.pointerId)){pointers.set(e.pointerId,pos);if(pointers.size===2){const p=[...pointers.values()],distance=Math.hypot(p[0].x-p[1].x,p[0].y-p[1].y);if(pinchDistance>0)setZoom(state.zoom*distance/pinchDistance);pinchDistance=distance;if(drag)drag.pinched=true;return;}if(drag){const dx=pos.x-drag.x,dy=pos.y-drag.y;if(Math.hypot(pos.x-drag.start.x,pos.y-drag.start.y)>4)drag.moved=true;if(state.mode==='3d'){velocity={x:dx*.005,y:dy*.005};state.yaw+=velocity.x;state.pitch=Math.max(-1.1,Math.min(1.1,state.pitch+velocity.y));}drag.x=pos.x;drag.y=pos.y;schedule();}return;}
 const point=M.pick(projected,pos.x,pos.y);hovered=point?point.i:-1;const tip=$('sample-tooltip');tip.hidden=!point;if(point){const s=demo.samples[point.i];tip.textContent=`${s.id} · ${groups[s.group]}`;tip.style.left=`${Math.max(6,Math.min(width-180,pos.x+14))}px`;tip.style.top=`${Math.max(4,pos.y-34)}px`;}schedule();});
function release(e,canceled=false){const pos=position(e),was=drag;pointers.delete(e.pointerId);if(!canceled&&was&&!was.moved&&!was.pinched){const point=M.pick(projected,pos.x,pos.y);if(point)selectSample(point.i);}if(pointers.size){const next=[...pointers.values()][0];drag={...next,start:next,moved:true,pinched:true};}else{drag=null;pinchDistance=0;}if(canceled)velocity={x:0,y:0};schedule();}
canvas.addEventListener('pointerup',e=>release(e));canvas.addEventListener('pointercancel',e=>release(e,true));canvas.addEventListener('pointerleave',()=>{hovered=-1;$('sample-tooltip').hidden=true;schedule();});
canvas.addEventListener('keydown',e=>{if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','+','=','-','Escape'].includes(e.key))return;e.preventDefault();stopRotation();if(e.key==='+'||e.key==='=')setZoom(state.zoom+.1);else if(e.key==='-')setZoom(state.zoom-.1);else if(e.key==='Escape'){state.yaw=-.55;state.pitch=.28;setZoom(1);}else if(state.mode==='3d'){state.yaw+=(e.key==='ArrowLeft'?-.08:e.key==='ArrowRight'?.08:0);state.pitch=Math.max(-1.1,Math.min(1.1,state.pitch+(e.key==='ArrowUp'?-.08:e.key==='ArrowDown'?.08:0)));}schedule();});
$('download-demo').addEventListener('click',()=>{const rows=[['Sample_ID','Group','Batch','PC1','PC2','PC3','PCA_scaled','Synthetic_data',...demo.genes],...demo.samples.map((s,i)=>[s.id,groups[s.group],s.batch+1,...result.scores[i].map(v=>v.toFixed(6)),state.scale,'TRUE',...s.values.map(v=>v.toFixed(6))])];const csv=rows.map(row=>row.join(',')).join('\r\n');const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'}));const a=document.createElement('a');a.href=url;a.download='GEOPrism-synthetic-demo.csv';document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),5000);text('explorer-status','Exported all 72 synthetic samples');});
new ResizeObserver(resize).observe(canvas.parentElement);
if('IntersectionObserver'in window)new IntersectionObserver(entries=>{inView=entries[0].isIntersecting;if(inView){lastFrame=0;schedule();}},{threshold:.05}).observe(canvas);
document.addEventListener('visibilitychange',()=>{if(!document.hidden){lastFrame=0;schedule();}});reducedMotion.addEventListener('change',()=>{if(reducedMotion.matches){stopRotation();schedule();}});
try{recalculate();refresh();resize();}catch(error){text('explorer-status',`Demo error: ${error.message}`);}
})();

const {test}=require('node:test');
const assert=require('node:assert/strict');
const {createDemo,pca,project,pick}=require('../docs/assets/explorer-core.js');
const demo=createDemo();
test('synthetic dataset is deterministic and balanced',()=>{
 assert.deepEqual(demo,createDemo());assert.equal(demo.samples.length,72);assert.equal(demo.genes.length,36);
 for(let group=0;group<3;group++)assert.equal(demo.samples.filter(s=>s.group===group).length,24);
 assert.equal(new Set(demo.samples.map(s=>s.id)).size,72);
});
for(const scaled of[false,true])test(`PCA has centered scores, orthogonal loadings, and valid eigenpairs (scaled=${scaled})`,()=>{
 const r=pca(demo.samples.map(s=>s.values),scaled);
 assert.ok(Math.abs(r.variance.reduce((a,b)=>a+b,0)-100)<1e-8);
 for(let i=1;i<r.eigenvalues.length;i++)assert.ok(r.eigenvalues[i]<=r.eigenvalues[i-1]+1e-9);
 for(let k=0;k<3;k++){
  assert.ok(Math.abs(r.scores.reduce((sum,row)=>sum+row[k],0))<1e-8);
  const v=r.loadings[k],lambda=r.eigenvalues[k];
  const residual=r.covariance.map(row=>row.reduce((sum,a,j)=>sum+a*v[j],0)).map((a,j)=>a-lambda*v[j]);
  assert.ok(Math.hypot(...residual)<1e-7);
  for(let j=0;j<3;j++){const dot=v.reduce((sum,value,i)=>sum+value*r.loadings[j][i],0);assert.ok(Math.abs(dot-(j===k?1:0))<1e-8);}
 }
 if(scaled)assert.ok(Math.abs(r.eigenvalues.reduce((a,b)=>a+b,0)-36)<1e-8);
});
test('rank-one data has all variance in one component',()=>{
 const r=pca([[1,2,3],[2,4,6],[3,6,9],[4,8,12]]);assert.ok(Math.abs(r.variance[0]-100)<1e-8);
});
test('invalid and constant data fail explicitly',()=>{
 assert.throws(()=>pca([[1,2],[3,4]]));assert.throws(()=>pca([[1,2],[3,NaN],[4,6]]));assert.throws(()=>pca([[1,1],[1,1],[1,1]]));assert.throws(()=>pca([[1,2],[2],[3,4]]));
});
test('projection responds to orbit and preserves 2D x/y independent of z',()=>{
 const camera={mode:'3d',yaw:0,pitch:0,zoom:1};const first=project([1,.5,.7],camera,800,500),turned=project([1,.5,.7],{...camera,yaw:1},800,500);
 assert.ok(Math.abs(first.x-turned.x)>1);
 const a=project([1,.5,-1],{...camera,mode:'2d'},800,500),b=project([1,.5,1],{...camera,mode:'2d'},800,500);
 assert.equal(a.x,b.x);assert.equal(a.y,b.y);assert.ok(Number.isFinite(turned.x));
});
test('point picking ignores distant samples and chooses the closest',()=>{
 const points=[{i:0,x:100,y:100},{i:1,x:110,y:100}];assert.equal(pick(points,108,100).i,1);assert.equal(pick(points,300,300),null);
});

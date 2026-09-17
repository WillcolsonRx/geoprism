/* Deterministic synthetic data and centered PCA. No GEO records or network requests. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.GEOPrismMath=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
function createDemo(seed=2417){
 let state=seed>>>0;
 const uniform=()=>{state=(Math.imul(1664525,state)+1013904223)>>>0;return(state+1)/4294967297;};
 const normal=()=>Math.sqrt(-2*Math.log(uniform()))*Math.cos(2*Math.PI*uniform());
 const genes=Array.from({length:36},(_,j)=>`Feature ${String(j+1).padStart(2,'0')}`);
 const samples=Array.from({length:72},(_,i)=>{const group=Math.floor(i/24),batch=i%2;
 const a=normal()*.72+[-1.55,1.5,.15][group],b=normal()*.6+[-.7,-.65,1.5][group],c=normal()*.55+(batch?.48:-.48);
 const values=genes.map((_,j)=>7+.7*Math.sin(j*.8)+a*Math.cos(j*.52)*(1+(j%5)*.14)+b*Math.sin(j*.41)+c*Math.cos(j*.91)+normal()*.48);
 return{id:`DEMO-${String(i+1).padStart(3,'0')}`,group,batch,values};});return{genes,samples};
}
function pca(rows,scale=false){
 if(!Array.isArray(rows)||rows.length<3||!Array.isArray(rows[0])||rows[0].length<2)throw Error('PCA needs at least three rows and two features.');
 const n=rows.length,m=rows[0].length;
 if(rows.some(row=>row.length!==m||row.some(v=>!Number.isFinite(v))))throw Error('PCA requires a finite rectangular matrix.');
 const means=Array.from({length:m},(_,j)=>rows.reduce((sum,row)=>sum+row[j],0)/n);
 const deviations=means.map((mean,j)=>Math.sqrt(rows.reduce((sum,row)=>sum+(row[j]-mean)**2,0)/(n-1)));
 const x=rows.map(row=>row.map((v,j)=>(v-means[j])/(scale&&deviations[j]>1e-12?deviations[j]:1)));
 const covariance=Array.from({length:m},()=>Array(m).fill(0));
 for(let j=0;j<m;j++)for(let k=j;k<m;k++){const v=x.reduce((sum,row)=>sum+row[j]*row[k],0)/(n-1);covariance[j][k]=covariance[k][j]=v;}
 const a=covariance.map(row=>row.slice()),vectors=Array.from({length:m},(_,i)=>Array.from({length:m},(_,j)=>i===j?1:0));
 let converged=false;
 for(let iter=0;iter<m*m*60;iter++){
  let largest=0,p=0,q=1;
  for(let j=0;j<m;j++)for(let k=j+1;k<m;k++)if(Math.abs(a[j][k])>largest){largest=Math.abs(a[j][k]);p=j;q=k;}
  if(largest<1e-10){converged=true;break;}
  const angle=.5*Math.atan2(2*a[p][q],a[q][q]-a[p][p]),c=Math.cos(angle),s=Math.sin(angle),app=a[p][p],aqq=a[q][q],apq=a[p][q];
  a[p][p]=c*c*app-2*s*c*apq+s*s*aqq;a[q][q]=s*s*app+2*s*c*apq+c*c*aqq;a[p][q]=a[q][p]=0;
  for(let k=0;k<m;k++){
   if(k!==p&&k!==q){const kp=a[k][p],kq=a[k][q];a[k][p]=a[p][k]=c*kp-s*kq;a[k][q]=a[q][k]=s*kp+c*kq;}
   const vp=vectors[k][p],vq=vectors[k][q];vectors[k][p]=c*vp-s*vq;vectors[k][q]=s*vp+c*vq;
  }
 }
 if(!converged)throw Error('The demo eigensolver did not converge.');
 const order=Array.from({length:m},(_,i)=>i).sort((i,j)=>a[j][j]-a[i][i]),eigenvalues=order.map(i=>Math.max(0,a[i][i]));
 const total=eigenvalues.reduce((sum,v)=>sum+v,0);if(total<1e-12)throw Error('No variable features remain.');
 const loadings=order.map(i=>{const vector=vectors.map(row=>row[i]),biggest=vector.reduce((best,v,j)=>Math.abs(v)>Math.abs(vector[best])?j:best,0),sign=vector[biggest]<0?-1:1;return vector.map(v=>v*sign);});
 const scores=x.map(row=>loadings.slice(0,3).map(vector=>row.reduce((sum,v,j)=>sum+v*vector[j],0)));
 return{scores,loadings,eigenvalues,variance:eigenvalues.map(v=>v/total*100),covariance,means,scale};
}
function project(point,camera,width,height){
 const[x,y,z]=point,yaw=camera.mode==='2d'?0:camera.yaw,pitch=camera.mode==='2d'?0:camera.pitch;
 const rx=x*Math.cos(yaw)+z*Math.sin(yaw),rz=-x*Math.sin(yaw)+z*Math.cos(yaw),ry=y*Math.cos(pitch)-rz*Math.sin(pitch),depth=y*Math.sin(pitch)+rz*Math.cos(pitch);
 const perspective=camera.mode==='2d'?1:6/(6-depth),unit=Math.min(width,height)*.2*camera.zoom*perspective;
 return{x:width/2+rx*unit,y:height/2-ry*unit,depth,scale:perspective};
}
function pick(points,x,y,radius=16){let best=null,distance=radius;for(const p of points){const d=Math.hypot(p.x-x,p.y-y);if(d<distance){best=p;distance=d;}}return best;}
return{createDemo,pca,project,pick};
});

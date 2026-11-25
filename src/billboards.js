import * as THREE from 'three';

// Sprites 2D transparentes: ficam orientados para a câmera (billboarding).
// Usados em sinalização luminosa, vapor, poeira e indicadores distantes.
function makeTexture(kind) {
  const c=document.createElement('canvas'); c.width=256; c.height=256;
  const g=c.getContext('2d');
  if(kind==='hazard'){
    g.fillStyle='#171c1d';g.fillRect(0,0,256,256);
    g.strokeStyle='#f2bf36';g.lineWidth=15;g.strokeRect(10,10,236,236);
    g.fillStyle='#f2bf36';g.beginPath();g.moveTo(128,35);g.lineTo(222,205);g.lineTo(34,205);g.closePath();g.fill();
    g.fillStyle='#171c1d';g.font='bold 128px Arial';g.textAlign='center';g.fillText('!',128,172);
  } else if(kind==='steam'){
    const grad=g.createRadialGradient(128,128,8,128,128,120);
    grad.addColorStop(0,'rgba(185,205,207,.24)');grad.addColorStop(.45,'rgba(130,155,158,.12)');grad.addColorStop(1,'rgba(80,100,105,0)');
    g.fillStyle=grad;g.fillRect(0,0,256,256);
  } else if(kind==='glow'){
    const grad=g.createRadialGradient(128,128,2,128,128,124);
    grad.addColorStop(0,'rgba(255,55,34,.8)');grad.addColorStop(.25,'rgba(210,24,15,.35)');grad.addColorStop(1,'rgba(120,0,0,0)');
    g.fillStyle=grad;g.fillRect(0,0,256,256);
  } else {
    g.fillStyle='rgba(190,205,205,.9)';g.beginPath();g.arc(128,128,5,0,Math.PI*2);g.fill();
    for(let i=0;i<18;i++){const a=i*Math.PI*2/18;g.fillRect(128+Math.cos(a)*12,128+Math.sin(a)*12,2,2);}
  }
  const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;
}
export function addFacilityBillboards(scene) {
  const hazard=makeTexture('hazard'),steam=makeTexture('steam'),glow=makeTexture('glow'),dust=makeTexture('dust');
  const add=(texture,x,y,z,size,opacity=1)=>{const m=new THREE.Sprite(new THREE.SpriteMaterial({map:texture,transparent:true,opacity,depthWrite:false}));m.position.set(x,y,z);m.scale.set(size,size,1);scene.add(m);return m;};
  // Placas e avisos legíveis à distância, sem geometria pesada.
  for(const [x,z] of [[-6.9,-5],[6.9,2],[-6.9,11],[6.9,-11]]) add(hazard,x,2.12,z,.72,.9);
  // Vapor e luzes de emergência: sprites billboards baratos em vez de partículas 3D.
  const steamSprites=[];
  for(const [x,y,z,s] of [[-2.8,1.2,-8,2.2],[3.4,1.1,-2,1.8],[-4.5,.9,7,1.5]]) steamSprites.push(add(steam,x,y,z,s,.8));
  const redGlow=add(glow,0,2.35,-4,4.2,.8);
  // Poeira suspensa com pequeno número de sprites; movimento atualizado pelo relógio.
  const motes=[];
  for(let i=0;i<14;i++){const x=Math.sin(i*12.3)*5.5,z=-12+(i*1.83)%24,y=.45+(i%5)*.43;motes.push(add(dust,x,y,z,.18,.55));}
  return {update(time){steamSprites.forEach((s,i)=>{s.position.y=1.1+Math.sin(time*.7+i)*.12;s.material.opacity=.5+Math.sin(time*.5+i)*.12;});redGlow.material.opacity=.55+Math.sin(time*4)*.18;motes.forEach((m,i)=>{m.position.y=.45+(i%5)*.43+Math.sin(time*.4+i)*.08;});}};
}

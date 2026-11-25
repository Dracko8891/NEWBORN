import * as THREE from 'three';

// Cenografia modular: identidade visual, orientação espacial e leitura do ambiente.
export function buildFacility(scene) {
  const mat=(color,roughness=.78,metalness=.12)=>new THREE.MeshStandardMaterial({color,roughness,metalness});
  const steel=mat(0x343d40,.55,.55),paint=mat(0x596064,.82,.18),black=mat(0x111719,.7,.35),glass= new THREE.MeshStandardMaterial({color:0x16363b,metalness:.45,roughness:.22,emissive:0x06252a,emissiveIntensity:.5}),yellow=mat(0xc18c27,.7,.25),white=mat(0xb9c0bd),red=mat(0x6f1716,.65,.25);
  const add=(geo,material,x,y,z,parent=scene)=>{const m=new THREE.Mesh(geo,material);m.position.set(x,y,z);parent.add(m);return m;};
  const cube=(x,y,z,w,h,d,material)=>add(new THREE.BoxGeometry(w,h,d),material,x,y,z);
  // Revestimentos segmentados, com juntas, placas e perfis de manutenção.
  for(const side of [-1,1]){
    for(let z=-13;z<=13;z+=2.5){
      cube(side*7.82,1.5,z,.055,2.75,2.28,paint);
      cube(side*7.77,1.5,z+1.17,.12,2.8,.055,steel);
      for(let y=.55;y<2.6;y+=.62) cube(side*7.7,y,z,.08,.035,1.95,black);
      cube(side*7.66,2.83,z,.18,.12,2.15,steel);
      // pequenas caixas elétricas repetidas como referência de escala
      if(Math.abs(z)%5<1){cube(side*7.38,1.18,z,.48,.72,.2,steel);cube(side*7.36,1.38,z,.28,.12,.035,red);for(let k=0;k<3;k++)cube(side*7.35,1.12-k*.13,z+.03,.18,.025,.025,yellow);}
    }
    // tubulação industrial contínua e derivações
    const pipe=add(new THREE.CylinderGeometry(.075,.075,27,8),steel,side*7.28,2.55,0);pipe.rotation.x=Math.PI/2;
    for(let z=-12;z<=12;z+=6){const elbow=add(new THREE.CylinderGeometry(.055,.055,.7,8),yellow,side*7.28,2.2,z);elbow.rotation.z=Math.PI/2;}
    // janelas de observação para dar profundidade e marcos de setor
    for(const z of [-8,4]){
      cube(side*7.65,1.75,z, .12,1.15,2.8,black);
      cube(side*7.57,1.75,z, .035,.92,2.5,glass);
      for(let k=-1;k<=1;k++)cube(side*7.5,1.75,z+k*.82,.035,.95,.035,steel);
    }
  }
  // Pilares, vigas, luminárias, placas de setor e faixas de risco.
  for(let z=-12;z<=12;z+=4){
    for(const x of [-6.8,6.8]){cube(x,1.5,z,.28,3,.32,steel);cube(x,2.92,z,.42,.13,.48,yellow);}
    cube(0,3.02,z,13.5,.16,.22,steel);
    cube(0,2.91,z,1.25,.09,.55,black);
    const lamp=add(new THREE.BoxGeometry(1.15,.045,.25),mat(0x9cb5b8,.25,.1,0x173c44),0,2.79,z);
    lamp.material.emissive=new THREE.Color(0x1c5960);lamp.material.emissiveIntensity=.45;
  }
  function sign(text,x,y,z,rotation=0,color='#f2c14e'){
    const canvas=document.createElement('canvas');canvas.width=512;canvas.height=128;const c=canvas.getContext('2d');
    c.fillStyle='#11191b';c.fillRect(0,0,512,128);c.strokeStyle=color;c.lineWidth=8;c.strokeRect(5,5,502,118);
    c.fillStyle=color;c.font='bold 48px Arial';c.textAlign='center';c.textBaseline='middle';c.fillText(text,256,65);
    const tex=new THREE.CanvasTexture(canvas);tex.colorSpace=THREE.SRGBColorSpace;
    const mesh=add(new THREE.PlaneGeometry(2.5,.62),new THREE.MeshBasicMaterial({map:tex}),x,y,z);mesh.rotation.y=rotation;
  }
  sign('LABORATÓRIO BIOLÓGICO  /  SETOR B',-7.48,2.55,1,Math.PI/2);
  sign('MANUTENÇÃO  •  B-03',7.48,2.5,-7,-Math.PI/2);
  sign('ACESSO RESTRITO  /  CONTENÇÃO',0,2.55,-14.78,0,'#e24a3b');
  // consoles, armários, caixas de transporte e macas técnicas
  for(const [x,z] of [[-5.8,-10.5],[-5.8,-7.8],[-5.8,8.4],[5.8,-1.2],[5.8,10.8]]){
    cube(x,.58,z,1.5,1.05,.75,steel);cube(x,.17,z,1.58,.12,.82,black);
    cube(x,1.16,z-.18,1.35,.08,.35,black);cube(x,1.22,z-.2,1.1,.035,.24,glass);
    for(let i=0;i<4;i++)cube(x-.48+i*.32,.82,z-.39,.18,.025,.02,i%2?yellow:red);
  }
  for(const [x,z] of [[-3.8,-4.8],[4.1,5.2],[-5.5,12]]){
    cube(x,.48,z,1.1,.9,.85,black);cube(x,.96,z,.96,.08,.72,steel);
    for(let k=0;k<3;k++)cube(x-.35+k*.35,.49,z-.44,.18,.48,.035,paint);
  }
  // grelhas de drenagem, trilhos no piso, faixas de segurança e manchas de óleo discretas
  for(let z=-12;z<=12;z+=6){
    cube(0,-.005,z,1.35,.025,1.8,black);
    for(let x=-.55;x<=.55;x+=.18)cube(x,.012,z,.025,.018,1.65,steel);
    for(const side of [-1,1])cube(side*6.35,.012,z,1.1,.018,1.7,yellow);
  }
  for(let z=-13;z<=13;z+=3){
    for(const side of [-1,1]){
      const stripe=cube(side*6.55,.025,z,.16,.025,1.1,yellow);stripe.rotation.y=.18;
    }
  }
  // ventilação no teto
  for(const z of [-10,-2,6,12]){
    cube(0,2.83,z,2.6,.12,.72,steel);
    for(let x=-1;x<=1;x+=.25)cube(x,2.75,z,.035,.08,.62,black);
  }
}

import fs from 'node:fs';import assert from 'node:assert/strict';
const js=fs.readFileSync('src/main.js','utf8'),css=fs.readFileSync('src/style.css','utf8'),html=fs.readFileSync('index.html','utf8'),icon=fs.readFileSync('public/icon.svg','utf8');
for(const c of ['DESPERTAR','SEM ENERGIA','PROTOCOLO DE CONTENÇÃO','RUÍDO NO ESCURO','ÚLTIMA AUTORIZAÇÃO','SUPERFÍCIE'])assert(js.includes(c),'Capítulo ausente: '+c);
for(const c of ['INVENTÁRIO','LANTERNA','CORRER','AGACHAR','INTERAGIR','OBJETIVO PRINCIPAL'])assert((html+js).includes(c),'HUD ausente: '+c);
assert(js.includes('new THREE.SpotLight')&&js.includes('camera.add(hand)'),'Lanterna de mão não encontrada');
assert(js.includes('camera.add(flashlight)')&&js.includes('camera.add(flashlight.target)'),'Lanterna não acompanha a câmera');
assert(js.includes('function startPuzzle()')&&js.includes('CONFIRMAR')&&js.includes("entered===ch.code"),'Puzzle de código incompleto');
assert(js.includes('CÓDIGO DO TERMINAL'),'Pista do puzzle ausente');
assert(!js.includes("sprite(dangerTex"),'Marcador flutuante antigo ainda presente');

assert(js.includes('monsterAI')&&js.includes('collides')&&js.includes('localStorage'),'IA, colisão ou salvamento ausente');
assert(css.includes('@media(orientation:portrait)'),'Orientação paisagem não tratada');
assert(css.includes('#sprint{right:18px;bottom:218px')&&css.includes('#crouch{right:18px;bottom:146px')&&css.includes('#use{right:18px;bottom:70px'),'Controles touch não estão separados');
assert(icon.includes('<svg')&&icon.includes('NEWBORN'),'Ícone ausente');
console.log('NEWBORN rebuild: validação estrutural aprovada');
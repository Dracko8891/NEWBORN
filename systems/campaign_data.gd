extends RefCounted
class_name NewbornCampaign

const CHAPTERS := [
	{"title":"O Silêncio Após o Grito","sector":"Ala Médica","summary":"Sobreviva à primeira caçada, encontre o Kit Estanca e o crachá, restaure os relés e abra a comporta com o PIN 0719.","objectives":["Investigue a triagem e recolha o Kit Estanca","Encontre o crachá Supervisor e descubra o PIN 0719","Restaure os relés Azul-Ciano e Âmbar","Escape do armário e abra a comporta 0719","Siga o pedido de socorro de Clara Sato"],"safe_room":false},
	{"title":"O Coração de Aço","sector":"Átrio Central","summary":"Explore o Átrio, calibre os dois Chips de recepção, registre-se na Safe Room e rastreie o cabo oeste com o Tricorder.","objectives":["Acesse as recepções Leste e Oeste e recolha os Chips de Calibração","Calibre a matriz com os dois Chips","Encontre a Safe Room e guarde recursos","Rastreie o cabo oeste com o Tricorder","Desative o campo da Ala Leste usando a Chave Dielétrica"],"safe_room":true},
	{"title":"A Armadilha da Empatia","sector":"Alojamentos e Psicologia","summary":"Investigue os registros, reproduza a sequência musical e sobreviva ao mimetismo vocal.","objectives":["Descubra o código Gamma 0315","Encontre os sinalizadores UV","Reproduza Dó-Mi-Sol-Ré-Lá na terapia","Obtenha o Chip Alpha e atualize o Tricorder","Escape do refeitório e retorne ao Átrio"],"safe_room":false},
	{"title":"Tanques de Gênese","sector":"Bio-Cultura e Síntese","summary":"Use a máscara, formule o composto e atravesse a área contaminada pela rota superior.","objectives":["Equipe a máscara de gás e o cinto de oito slots","Reúna 2 Nitro-Estéril, 1 Ácido Tampão e 3 Enzimas","Drene a névoa de amônia","Acione as válvulas Azul, Verde e Vermelha","Recupere o Chip Beta"],"safe_room":false},
	{"title":"Apagão do Núcleo","sector":"Engenharia Profunda","summary":"Balanceie a carga, opere os braços robóticos e atravesse a câmara no breu.","objectives":["Alcance a Safe Room da Engenharia","Desligue a iluminação para energizar o Cofre Gamma","Opere os três braços robóticos e as câmeras","Use o arco elétrico para cegar o Newborn e escape","Recupere o Chip Gamma e insira Beta/Gamma no pedestal"],"safe_room":true},
	{"title":"Berçário Proibido","sector":"Subnível Omega","summary":"Escaneie os quatro estágios de evolução, complete o download de 01:15 e atravesse o cerco com recursos limitados.","objectives":["Escaneie os tubos com Tricorder Nv2","Ordene os biochips: Celular, Esquelético, Neural, Despertar","Inicie o download de 01:15 na Câmara 00","Sobreviva ao cerco usando quatro passagens e duas baterias","Obtenha o Master Omega Card e acesse a escotilha"],"safe_room":false},
	{"title":"Ruptura e Liberdade Fatal","sector":"Hangar de Carga","summary":"Acople os sistemas hidráulicos, execute o Override e fuja sem perceber que libertou a criatura.","objectives":["Atravesse o Átrio em colapso e alcance o hangar","Conecte os três acoplamentos hidráulicos","Insira o Master Omega Card na cabine","Execute o Override e escape pelo portão","Acione o selamento externo e descubra o destino do Newborn"],"safe_room":false}
]

static func get_chapter(index: int) -> Dictionary:
	if index < 1 or index > CHAPTERS.size():
		return {}
	return CHAPTERS[index - 1].duplicate(true)

extends RefCounted
class_name NewbornWorldMap

## Topology of Vanguard-7. This is map data, not yet a rendered holographic map.
## Connections preserve the intended backtracking and sector transitions.

const ROOMS := [
	{"id":"c1_security","chapter":1,"name":"Sala de Segurança","sector":"Ala Médica","kind":"room"},
	{"id":"c1_infirmary","chapter":1,"name":"Enfermaria","sector":"Ala Médica","kind":"room"},
	{"id":"c1_archive","chapter":1,"name":"Arquivo Clínico","sector":"Ala Médica","kind":"optional_room"},
	{"id":"c2_calibration_depot","chapter":2,"name":"Depósito de Calibragem","sector":"Hub Central","kind":"optional_room"},
	{"id":"c3_dressing","chapter":3,"name":"Vestiário da Tripulação","sector":"Alojamentos e Psicologia","kind":"optional_room"},
	{"id":"c4_observation","chapter":4,"name":"Observação Biológica","sector":"Bio-Cultura e Síntese","kind":"optional_room"},
	{"id":"c5_workshop","chapter":5,"name":"Oficina de Manutenção","sector":"Engenharia Profunda","kind":"optional_room"},
	{"id":"c6_omega_observation","chapter":6,"name":"Observação Ômega","sector":"Subnível Ômega","kind":"optional_room"},
	{"id":"c7_service_dock","chapter":7,"name":"Doca de Serviço","sector":"Hangar","kind":"optional_room"},
	{"id":"c1_triage","chapter":1,"name":"Sala de Triagem","sector":"Ala Médica","kind":"room"},
	{"id":"c1_relay","chapter":1,"name":"Painel de Relés","sector":"Ala Médica","kind":"puzzle"},
	{"id":"c1_hatch","chapter":1,"name":"Comporta do Átrio","sector":"Ala Médica","kind":"locked_exit"},
	{"id":"c2_atrium","chapter":2,"name":"Átrio Central — Saguão","sector":"Hub Central","kind":"hub"},
	{"id":"c2_east","chapter":2,"name":"Recepção Leste","sector":"Hub Central","kind":"room"},
	{"id":"c2_west","chapter":2,"name":"Recepção Oeste","sector":"Hub Central","kind":"room"},
	{"id":"c2_matrix","chapter":2,"name":"Matriz de DNA","sector":"Hub Central","kind":"puzzle"},
	{"id":"c2_safe","chapter":2,"name":"Sala Segura Central","sector":"Hub Central","kind":"safe_room"},
	{"id":"c2_west_cable","chapter":2,"name":"Corredor do Cabo Oeste","sector":"Hub Central","kind":"puzzle"},
	{"id":"c3_quarters","chapter":3,"name":"Cabines da Tripulação","sector":"Alojamentos e Psicologia","kind":"room"},
	{"id":"c3_locker","chapter":3,"name":"Armário do Turno Gama","sector":"Alojamentos e Psicologia","kind":"item_room"},
	{"id":"c3_therapy","chapter":3,"name":"Sala de Terapia Sonora","sector":"Alojamentos e Psicologia","kind":"puzzle_safe"},
	{"id":"c3_cafeteria","chapter":3,"name":"Refeitório","sector":"Alojamentos e Psicologia","kind":"encounter"},
	{"id":"c4_upper","chapter":4,"name":"Passarela Superior Respirável","sector":"Bio-Cultura e Síntese","kind":"safe_route"},
	{"id":"c4_synthesis","chapter":4,"name":"Cabine de Síntese","sector":"Bio-Cultura e Síntese","kind":"puzzle"},
	{"id":"c4_lower","chapter":4,"name":"Piso Inferior — Tanques","sector":"Bio-Cultura e Síntese","kind":"hazard"},
	{"id":"c4_valves","chapter":4,"name":"Galeria de Válvulas","sector":"Bio-Cultura e Síntese","kind":"puzzle"},
	{"id":"c4_pit","chapter":4,"name":"Poço Drenado","sector":"Bio-Cultura e Síntese","kind":"item_room"},
	{"id":"c5_safe","chapter":5,"name":"Sala Segura da Engenharia","sector":"Engenharia Profunda","kind":"safe_room"},
	{"id":"c5_load","chapter":5,"name":"Controle de Carga","sector":"Engenharia Profunda","kind":"puzzle"},
	{"id":"c5_jeffries","chapter":5,"name":"Tubos de Jeffries","sector":"Engenharia Profunda","kind":"stealth_route"},
	{"id":"c5_core","chapter":5,"name":"Câmara do Núcleo de Plasma","sector":"Engenharia Profunda","kind":"encounter"},
	{"id":"c5_gamma","chapter":5,"name":"Cofre Gama","sector":"Engenharia Profunda","kind":"locked_item"},
	{"id":"c6_lab","chapter":6,"name":"Laboratório Ômega","sector":"Subnível Ômega","kind":"room"},
	{"id":"c6_tubes","chapter":6,"name":"Galeria dos Quatro Estágios","sector":"Subnível Ômega","kind":"puzzle"},
	{"id":"c6_chamber","chapter":6,"name":"Câmara de Contenção 00","sector":"Subnível Ômega","kind":"arena"},
	{"id":"c6_download","chapter":6,"name":"Terminal Mestre","sector":"Subnível Ômega","kind":"timed_event"},
	{"id":"c6_maintenance","chapter":6,"name":"Escotilha de Manutenção","sector":"Subnível Ômega","kind":"transition"},
	{"id":"c7_atrium","chapter":7,"name":"Átrio em Colapso","sector":"Retorno ao Hub","kind":"hub"},
	{"id":"c7_cargo_lift","chapter":7,"name":"Elevador de Carga","sector":"Hangar","kind":"transition"},
	{"id":"c7_hangar","chapter":7,"name":"Hangar de Carga","sector":"Hangar","kind":"encounter"},
	{"id":"c7_couplings","chapter":7,"name":"Pátio dos Acoplamentos","sector":"Hangar","kind":"puzzle"},
	{"id":"c7_override","chapter":7,"name":"Cabine do Override","sector":"Comporta Externa","kind":"story_choice"},
	{"id":"c7_tunnel","chapter":7,"name":"Túnel de Descompressão","sector":"Comporta Externa","kind":"final_escape"},
	{"id":"surface","chapter":7,"name":"Encosta Nevada e Chaminés","sector":"Superfície","kind":"epilogue"}
]

const CONNECTIONS := [
	{"from":"c1_security","to":"c1_triage","type":"door","state":"open"},
	{"from":"c1_triage","to":"c1_archive","type":"side_room","state":"open"},
	{"from":"c1_hatch","to":"c1_infirmary","type":"side_room","state":"open"},
	{"from":"c2_west","to":"c2_calibration_depot","type":"side_room","state":"open"},
	{"from":"c3_cafeteria","to":"c3_dressing","type":"side_room","state":"open"},
	{"from":"c4_synthesis","to":"c4_observation","type":"side_room","state":"open"},
	{"from":"c5_load","to":"c5_workshop","type":"side_room","state":"open"},
	{"from":"c6_tubes","to":"c6_omega_observation","type":"side_room","state":"open"},
	{"from":"c7_hangar","to":"c7_service_dock","type":"side_room","state":"open"},
	{"from":"c1_triage","to":"c1_relay","type":"corridor","state":"open"},
	{"from":"c1_relay","to":"c1_hatch","type":"pneumatic_door","state":"locked_until_relays_and_pin"},
	{"from":"c1_hatch","to":"c2_atrium","type":"chapter_transition","state":"pin_0719"},
	{"from":"c2_atrium","to":"c2_east","type":"door","state":"locked_by_field"},
	{"from":"c2_atrium","to":"c2_west","type":"door","state":"open"},
	{"from":"c2_east","to":"c2_matrix","type":"corridor","state":"open"},
	{"from":"c2_west","to":"c2_matrix","type":"corridor","state":"open"},
	{"from":"c2_matrix","to":"c2_safe","type":"heavy_door","state":"two_calibration_chips"},
	{"from":"c2_safe","to":"c2_west_cable","type":"door","state":"dielectric_key"},
	{"from":"c2_west_cable","to":"c3_quarters","type":"jeffries_tube","state":"east_field_disabled"},
	{"from":"c3_quarters","to":"c3_locker","type":"door","state":"code_0315"},
	{"from":"c3_quarters","to":"c3_therapy","type":"door","state":"open"},
	{"from":"c3_therapy","to":"c3_cafeteria","type":"door","state":"melody_c_e_g_d_a"},
	{"from":"c3_cafeteria","to":"c2_atrium","type":"shortcut","state":"unlocked_after_encounter"},
	{"from":"c2_atrium","to":"c4_upper","type":"elevator","state":"beta_access"},
	{"from":"c4_upper","to":"c4_synthesis","type":"door","state":"clean_route"},
	{"from":"c4_synthesis","to":"c4_lower","type":"stairwell","state":"mask_and_filters_recommended"},
	{"from":"c4_lower","to":"c4_valves","type":"flooded_corridor","state":"toxic"},
	{"from":"c4_valves","to":"c4_pit","type":"drain_gate","state":"blue_green_red"},
	{"from":"c4_pit","to":"c5_safe","type":"service_stairwell","state":"drained"},
	{"from":"c5_safe","to":"c5_load","type":"door","state":"open"},
	{"from":"c5_load","to":"c5_jeffries","type":"maintenance_hatch","state":"lights_off"},
	{"from":"c5_jeffries","to":"c5_core","type":"duct","state":"open"},
	{"from":"c5_core","to":"c5_gamma","type":"magnetic_safe","state":"thermal_coil_and_power"},
	{"from":"c5_gamma","to":"c2_atrium","type":"service_elevator","state":"gamma_chip"},
	{"from":"c2_atrium","to":"c6_lab","type":"central_elevator","state":"three_isolinear_chips"},
	{"from":"c6_lab","to":"c6_tubes","type":"laboratory_door","state":"tricorder_level_2"},
	{"from":"c6_tubes","to":"c6_chamber","type":"containment_door","state":"biochip_sequence"},
	{"from":"c6_chamber","to":"c6_download","type":"inner_hatch","state":"open"},
	{"from":"c6_download","to":"c6_maintenance","type":"maintenance_hatch","state":"download_complete_and_omega_card"},
	{"from":"c6_maintenance","to":"c7_atrium","type":"elevator_transition","state":"omega_card"},
	{"from":"c7_atrium","to":"c7_cargo_lift","type":"cargo_elevator","state":"structural_failure"},
	{"from":"c7_cargo_lift","to":"c7_hangar","type":"heavy_door","state":"open"},
	{"from":"c7_hangar","to":"c7_couplings","type":"hangar_route","state":"open"},
	{"from":"c7_couplings","to":"c7_override","type":"pneumatic_door","state":"three_hydraulic_couplings"},
	{"from":"c7_override","to":"c7_tunnel","type":"override_gate","state":"omega_card_and_override"},
	{"from":"c7_tunnel","to":"surface","type":"sliding_gate","state":"manual_emergency_seal"}
]

const KEY_ITEM_LOCATIONS := [
	{"item":"Crachá do Supervisor","room":"c1_triage","chapter":1},
	{"item":"Kit de Estanca inicial","room":"c1_triage","chapter":1},
	{"item":"Chips de Calibragem Leste/Oeste","room":"c2_east","chapter":2},
	{"item":"Hipo-Spray","room":"c2_west","chapter":2},
	{"item":"Chave Dielétrica","room":"c2_safe","chapter":2},
	{"item":"Sinalizadores UV (2)","room":"c3_locker","chapter":3},
	{"item":"Chip Isolinear Alfa e Tricorder Nv.2","room":"c3_therapy","chapter":3},
	{"item":"Máscara, Cinto Tático e filtros","room":"c4_upper","chapter":4},
	{"item":"Chip Isolinear Beta","room":"c4_pit","chapter":4},
	{"item":"Sinalizador UV de emergência","room":"c5_safe","chapter":5},
	{"item":"Chip Isolinear Gama","room":"c5_gamma","chapter":5},
	{"item":"Bio-Chips evolutivos","room":"c6_tubes","chapter":6},
	{"item":"Cartão Mestre Ômega","room":"c6_download","chapter":6},
	{"item":"3 Acoplamentos Hidráulicos","room":"c7_couplings","chapter":7}
]

static func get_rooms() -> Array:
	return ROOMS.duplicate(true)

static func get_connections() -> Array:
	return CONNECTIONS.duplicate(true)

static func get_item_locations() -> Array:
	return KEY_ITEM_LOCATIONS.duplicate(true)

static func get_room(room_id: String) -> Dictionary:
	for room in ROOMS:
		if str(room.id) == room_id:
			return room.duplicate(true)
	return {}

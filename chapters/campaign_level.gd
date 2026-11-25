extends Node3D
@export_range(1, 7) var chapter_number: int = 1

const MAT_WALL := preload("res://materials/medical_wall.tres")
const MAT_FLOOR := preload("res://materials/medical_floor.tres")
const MAT_ALERT := preload("res://materials/emergency_red.tres")
const Campaign = preload("res://systems/campaign_data.gd")

func _ready() -> void:
	_ensure_environment()
	# The main scene is the resume entry point; continue from the saved chapter.
	if chapter_number == 1 and GameState.chapter > 1:
		chapter_number = GameState.chapter
	var campaign_hud := CanvasLayer.new()
	campaign_hud.name = "CampaignHUD"
	campaign_hud.set_script(load("res://scripts/campaign_hud.gd"))
	add_child(campaign_hud)
	CampaignDirector.begin_chapter(chapter_number)
	_build_sector()
	_build_chapter_landmarks()
	_build_chapter_wings()
	_build_hide_spots()
	var chapter_data := Campaign.get_chapter(chapter_number)
	if bool(chapter_data.get("safe_room", false)):
		_build_safe_room()
	_build_supply_pickups()
	_build_objectives()
	_build_chapter_puzzle_stations()
	_spawn_hunter()

func _make_box(label: String, pos: Vector3, size: Vector3, mat: Material, solid: bool = true) -> void:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = label
	node.position = pos
	add_child(node)
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = mat
	node.add_child(mesh_node)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)

func _build_sector() -> void:
	var data := Campaign.get_chapter(chapter_number)
	var wall := _chapter_material(chapter_number, false)
	var floor_mat := _chapter_material(chapter_number, true)
	var alert := MAT_ALERT
	_make_box("Setor_Piso", Vector3(0, -0.2, 0), Vector3(18, 0.4, 70), floor_mat)
	_make_box("Setor_Teto", Vector3(0, 4.0, 0), Vector3(18, 0.3, 70), wall)
	_make_box("Parede_E", Vector3(-9.1, 2, 0), Vector3(0.3, 4, 70), wall)
	_make_box("Parede_D", Vector3(9.1, 2, 0), Vector3(0.3, 4, 70), wall)
	for i in range(11):
		var z := -32.0 + float(i) * 6.4
		_make_box("Arco_Estrutural_%02d" % i, Vector3(0, 3.65, z), Vector3(18, 0.35, 0.45), wall)
		_make_box("Painel_Tecnico_E_%02d" % i, Vector3(-8.88, 2.6, z + 2.1), Vector3(0.12, 1.4, 2.2), floor_mat, false)
		_make_box("Painel_Tecnico_D_%02d" % i, Vector3(8.88, 2.6, z + 2.1), Vector3(0.12, 1.4, 2.2), floor_mat, false)
	for side in [-1.0, 1.0]:
		for j in range(5):
			_make_box("Conduite_%d_%d" % [int(side), j], Vector3(side * 7.8, 3.25, -25.0 + float(j) * 12.0), Vector3(0.35, 0.35, 5.0), alert, false)
	_make_box("Console_Setor", Vector3(-6.8, 1.3, -10), Vector3(0.4, 1.8, 2.4), alert, false)
	_make_box("Porta_Saida", Vector3(0, 1.8, -34), Vector3(3.5, 3.6, 0.4), alert)
	_make_box("Mesa_Operacional", Vector3(4.8, 0.7, 2), Vector3(2.8, 1.4, 1.4), wall)
	_make_box("Armario_Industrial", Vector3(-5.8, 1.2, 10), Vector3(1.2, 2.4, 1.2), floor_mat)
	_make_box("Plataforma_Servico", Vector3(0, 1.0, 19), Vector3(8, 0.25, 4), wall)
	var player := get_node_or_null("Player")
	if player == null:
		_spawn_player()

func _spawn_player() -> void:
	var player_scene := load("res://scenes/player.tscn")
	if player_scene != null:
		var p: Node3D = player_scene.instantiate()
		p.name = "Player"
		p.position = Vector3(0, 1, 28)
		add_child(p)

func _build_objectives() -> void:
	var data := Campaign.get_chapter(chapter_number)
	var objectives: Array = data.get("objectives", [])
	for i in range(objectives.size()):
		var trigger := Area3D.new()
		trigger.name = "Objective_%02d" % (i + 1)
		trigger.position = Vector3(0, 1.1, 20.0 - float(i) * 11.0)
		trigger.set_script(load("res://scripts/objective_trigger.gd"))
		trigger.set("objective_id", "c%d_o%d" % [chapter_number, i + 1])
		trigger.set("prompt", str(objectives[i]))
		add_child(trigger)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 1.7
		collision.shape = shape
		trigger.add_child(collision)
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		marker.mesh = sphere
		marker.material_override = MAT_ALERT
		trigger.add_child(marker)
		var objective_sign := Label3D.new()
		objective_sign.name = "ObjectiveSign"
		objective_sign.text = "OBJ %02d" % (i + 1)
		objective_sign.position = Vector3(0, 0.9, 0)
		objective_sign.font_size = 30
		objective_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		objective_sign.modulate = Color(0.45, 0.95, 0.9)
		trigger.add_child(objective_sign)

func _spawn_hunter() -> void:
	var hunter_scene := load("res://ai/newborn_hunter.tscn")
	if hunter_scene == null:
		return
	var hunter: CharacterBody3D = hunter_scene.instantiate()
	hunter.name = "NewbornHunter"
	hunter.position = Vector3(0, 0.1, -18)
	add_child(hunter)

func _chapter_material(chapter: int, floor_surface: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var colors := [
		Color(0.22, 0.27, 0.29), Color(0.12, 0.24, 0.29),
		Color(0.26, 0.22, 0.29), Color(0.18, 0.31, 0.25),
		Color(0.16, 0.20, 0.24), Color(0.12, 0.13, 0.18),
		Color(0.26, 0.24, 0.20)
	]
	var base: Color = colors[clampi(chapter - 1, 0, 6)]
	if floor_surface:
		base = base.darkened(0.58)
	material.albedo_color = base
	material.metallic = 0.42 if not floor_surface else 0.62
	material.roughness = 0.68
	return material

func _build_chapter_landmarks() -> void:
	match chapter_number:
		1:
			for i in range(4):
				_make_box("Leito_Medico_%02d" % i, Vector3(-5.8, 0.55, -22.0 + float(i) * 5.5), Vector3(2.0, 1.1, 2.8), MAT_WALL)
			_make_box("Balcao_Recepcao", Vector3(5.5, 0.65, 12), Vector3(3.2, 1.3, 1.2), MAT_WALL)
		2:
			_make_box("Passarela_Mezzanino", Vector3(0, 3.0, -2), Vector3(14, 0.3, 18), MAT_WALL)
			for i in range(3):
				_make_cylinder("Nucleo_Holografico_%d" % i, Vector3(-4.5 + float(i) * 4.5, 1.6, -5), 0.7, 3.0, MAT_ALERT)
			_make_box("Matriz_Central", Vector3(0, 1.5, 8), Vector3(5.5, 2.6, 2.0), MAT_ALERT)
		3:
			for i in range(6):
				_make_box("Modulo_Alojamento_%02d" % i, Vector3(-6.0 + float(i % 2) * 12.0, 1.1, -22.0 + float(i / 2) * 7.0), Vector3(2.2, 2.2, 3.4), MAT_WALL)
			_make_box("Mesa_Terapia_Acustica", Vector3(0, 0.8, 4), Vector3(4.0, 1.6, 2.0), MAT_ALERT)
		4:
			for i in range(5):
				_make_cylinder("Tanque_Genese_%02d" % i, Vector3(-6.0 + float(i % 3) * 6.0, 2.0, -20.0 + float(i / 3) * 14.0), 1.25, 4.0, MAT_ALERT)
			_make_box("Passarela_Superior_Respiravel", Vector3(0, 2.1, 10), Vector3(15, 0.3, 5), MAT_WALL)
		5:
			_make_cylinder("Reator_Plasma", Vector3(0, 1.8, -12), 3.0, 5.5, MAT_ALERT)
			for i in range(3):
				_make_box("Passarela_Nucleo_%d" % i, Vector3(-5.0 + float(i) * 5.0, 1.0 + float(i % 2) * 0.7, -12), Vector3(1.2, 0.2, 17), MAT_WALL)
			_make_box("Console_Bracos_Roboticos", Vector3(6, 1.0, 10), Vector3(2.5, 2.0, 1.2), MAT_ALERT)
		6:
			for i in range(4):
				_make_cylinder("Tubo_Evolucao_%d" % i, Vector3(-6.0 + float(i) * 4.0, 2.0, -14), 0.85, 4.2, MAT_ALERT)
			_make_box("Camara_00", Vector3(0, 1.8, -28), Vector3(8, 3.6, 0.35), MAT_WALL)
			_make_box("Terminal_Download", Vector3(6, 1.2, -24), Vector3(1.0, 2.4, 1.0), MAT_ALERT)
		7:
			_make_box("Plataforma_Carga", Vector3(0, 0.5, -16), Vector3(14, 1.0, 18), MAT_WALL)
			_make_box("Cabine_Override", Vector3(-6, 1.8, -27), Vector3(3.0, 3.6, 3.0), MAT_ALERT)
			for i in range(3):
				_make_cylinder("Acoplamento_Hidraulico_%d" % i, Vector3(-5.0 + float(i) * 5.0, 1.1, -8), 0.45, 2.2, MAT_ALERT)


func _build_chapter_wings() -> void:
	var rooms: Array[Dictionary] = []
	match chapter_number:
		1:
			rooms = [{"name":"TRIAGEM","side":1.0,"z":-16.0},{"name":"ENFERMARIA","side":-1.0,"z":-30.0}]
		2:
			rooms = [{"name":"RECEPÇÃO LESTE","side":1.0,"z":-16.0},{"name":"MATRIZ CENTRAL","side":-1.0,"z":-30.0}]
		3:
			rooms = [{"name":"ALOJAMENTOS","side":1.0,"z":22.0},{"name":"PSICOLOGIA","side":-1.0,"z":-30.0}]
		4:
			rooms = [{"name":"CULTURA CELULAR","side":1.0,"z":22.0},{"name":"BANCADA DE SÍNTESE","side":-1.0,"z":-30.0}]
		5:
			rooms = [{"name":"CÂMARA DO REATOR","side":-1.0,"z":-30.0}]
		6:
			rooms = [{"name":"TUBOS EVOLUTIVOS","side":1.0,"z":22.0},{"name":"CÂMARA OMEGA","side":-1.0,"z":-30.0}]
		7:
			rooms = [{"name":"ÁTRIO RUPTURADO","side":1.0,"z":22.0},{"name":"HANGAR DE CARGA","side":1.0,"z":-30.0}]
	for index in range(rooms.size()):
		var room: Dictionary = rooms[index]
		var side := float(room.side)
		var center_z := float(room.z)
		var center_x := side * 6.55
		var front_x := side * 4.25
		var room_name := str(room.name)
		# Side walls and split front wall create a real doorway into each wing.
		_make_box("Wing_%d_SideA" % index, Vector3(center_x, 1.7, center_z - 3.85), Vector3(4.5, 3.4, 0.24), MAT_WALL)
		_make_box("Wing_%d_SideB" % index, Vector3(center_x, 1.7, center_z + 3.85), Vector3(4.5, 3.4, 0.24), MAT_WALL)
		_make_box("Wing_%d_DoorA" % index, Vector3(front_x, 1.7, center_z - 2.55), Vector3(0.24, 3.4, 2.6), MAT_WALL)
		_make_box("Wing_%d_DoorB" % index, Vector3(front_x, 1.7, center_z + 2.55), Vector3(0.24, 3.4, 2.6), MAT_WALL)
		_make_box("Wing_%d_Floor" % index, Vector3(center_x, 0.035, center_z), Vector3(4.45, 0.07, 7.45), MAT_FLOOR)
		_make_box("Wing_%d_Console" % index, Vector3(side * 7.75, 0.75, center_z), Vector3(0.9, 1.5, 1.3), MAT_ALERT)
		var sign := Label3D.new()
		sign.name = "WingSign_%d" % index
		sign.text = room_name
		sign.position = Vector3(side * 6.45, 2.75, center_z)
		sign.font_size = 34
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign.modulate = Color(0.42, 0.94, 0.9)
		add_child(sign)

func _make_cylinder(label: String, pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var node := Node3D.new()
	node.name = label
	node.position = pos
	add_child(node)
	var mesh_node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_node.mesh = mesh
	mesh_node.material_override = mat
	node.add_child(mesh_node)

func _ensure_environment() -> void:
	if get_tree().current_scene != null and get_tree().current_scene.find_child("WorldEnvironment", true, false) != null:
		return
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.018, 0.024)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.38, 0.42)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.16, 0.19, 0.21)
	env.fog_density = 0.018
	world.environment = env
	add_child(world)


func _build_safe_room() -> void:
	# Compact safe room beside the starting corridor; zone layer 2 is ignored by the interaction ray.
	_make_box("Sala_Segura_Piso", Vector3(0, 0.08, 23), Vector3(8.0, 0.16, 9.0), MAT_FLOOR)
	_make_box("Sala_Segura_Parede_E", Vector3(-4.1, 1.9, 23), Vector3(0.25, 3.8, 9.0), MAT_WALL)
	_make_box("Sala_Segura_Parede_D", Vector3(4.1, 1.9, 23), Vector3(0.25, 3.8, 9.0), MAT_WALL)
	_make_box("Sala_Segura_Parede_Fundo", Vector3(0, 1.9, 18.5), Vector3(8.0, 3.8, 0.25), MAT_WALL)
	var zone := Area3D.new()
	zone.name = "SafeRoomZone"
	zone.position = Vector3(0, 1.2, 23)
	zone.set_script(load("res://scripts/safe_room.gd"))
	add_child(zone)
	var zone_collision := CollisionShape3D.new()
	var zone_shape := BoxShape3D.new()
	zone_shape.size = Vector3(7.8, 3.4, 8.8)
	zone_collision.shape = zone_shape
	zone.add_child(zone_collision)
	var terminal := Area3D.new()
	terminal.name = "SafeStorageTerminal"
	terminal.position = Vector3(0, 1.0, 25.5)
	terminal.set_script(load("res://scripts/safe_storage_terminal.gd"))
	add_child(terminal)
	var terminal_collision := CollisionShape3D.new()
	var terminal_shape := BoxShape3D.new()
	terminal_shape.size = Vector3(1.8, 2.0, 0.9)
	terminal_collision.shape = terminal_shape
	terminal.add_child(terminal_collision)
	var console_mesh := MeshInstance3D.new()
	var console_box := BoxMesh.new()
	console_box.size = Vector3(1.25, 1.6, 0.55)
	console_mesh.mesh = console_box
	console_mesh.material_override = MAT_ALERT
	terminal.add_child(console_mesh)


func _build_supply_pickups() -> void:
	var supplies: Array[Dictionary] = []
	match chapter_number:
		1:
			supplies = [
				{"id":"kit_estanca","label":"Kit Estanca","position":Vector3(-5.5,0.8,5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(5.5,0.8,-5.0),"consumable":true},
				{"id":"supervisor_badge","label":"Crachá Supervisor","position":Vector3(5.5,0.8,10.0)},
				{"id":"pin_note_0719","label":"Anotação do PIN 0719","position":Vector3(-5.5,0.8,-2.0)}
			]
		2:
			supplies = [
				{"id":"kit_estanca","label":"Kit Estanca","position":Vector3(-5.5,0.8,5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(5.5,0.8,-5.0),"consumable":true},
				{"id":"calibration_chip_east","label":"Chip de Calibração Leste","position":Vector3(-5.5,0.8,12.0)},
				{"id":"calibration_chip_west","label":"Chip de Calibração Oeste","position":Vector3(5.5,0.8,2.0)},
				{"id":"dielectric_key","label":"Chave Dielétrica","position":Vector3(-5.5,0.8,-20.0)}
			]
		3:
			supplies = [
				{"id":"kit_estanca","label":"Kit Estanca","position":Vector3(-5.5,0.8,5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(5.5,0.8,-5.0),"consumable":true},
				{"id":"uv_flare","label":"Sinalizador UV","position":Vector3(-5.5,0.8,12.0),"consumable":true},
				{"id":"alpha_chip","label":"Chip Alpha","position":Vector3(-6.0,0.8,-18.0)},
				{"id":"tricorder_upgrade","label":"Módulo Tricorder Nv2","position":Vector3(5.5,0.8,-20.0)}
			]
		4:
			supplies = [
				{"id":"kit_estanca","label":"Kit Estanca","position":Vector3(-5.5,0.8,5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(5.5,0.8,-5.0),"consumable":true},
				{"id":"gas_mask","label":"Máscara de Gás","position":Vector3(-5.5,0.8,12.0)},
				{"id":"nitro_sterile","label":"Nitro-Estéril","position":Vector3(5.5,0.8,12.0),"consumable":true},
				{"id":"nitro_sterile","label":"Nitro-Estéril","position":Vector3(6.5,0.8,12.0),"consumable":true},
				{"id":"acid_buffer","label":"Ácido Tampão","position":Vector3(-5.5,0.8,-5.0),"consumable":true},
				{"id":"enzyme","label":"Enzima de Síntese","position":Vector3(5.5,0.8,-18.0),"consumable":true},
				{"id":"enzyme","label":"Enzima de Síntese","position":Vector3(6.5,0.8,-18.0),"consumable":true},
				{"id":"enzyme","label":"Enzima de Síntese","position":Vector3(7.5,0.8,-18.0),"consumable":true},
				{"id":"beta_chip","label":"Chip Beta","position":Vector3(6.0,0.8,-25.0)}
			]
		5:
			supplies = [
				{"id":"kit_estanca","label":"Kit Estanca","position":Vector3(-5.5,0.8,5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(5.5,0.8,-5.0),"consumable":true},
				{"id":"gamma_chip","label":"Chip Gamma","position":Vector3(-6.0,0.8,-25.0)},
				{"id":"electric_arc","label":"Arco Elétrico","position":Vector3(6.0,0.8,10.0)}
			]
		6:
			supplies = [
				{"id":"kit_estanca","label":"Kit Estanca","position":Vector3(-5.5,0.8,5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(5.5,0.8,-5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(-5.5,0.8,-5.0),"consumable":true},
				{"id":"omega_master_card","label":"Cartão Mestre Ômega","position":Vector3(-6.0,0.8,-27.0)}
			]
		7:
			supplies = [
				{"id":"kit_estanca","label":"Kit Estanca","position":Vector3(-5.5,0.8,5.0),"consumable":true},
				{"id":"battery","label":"Bateria de lanterna","position":Vector3(5.5,0.8,-5.0),"consumable":true}
			]
	for index in range(supplies.size()):
		var supply: Dictionary = supplies[index]
		var pickup := Area3D.new()
		pickup.name = "Pickup_%s_%02d" % [str(supply.id), index + 1]
		pickup.position = supply.position
		pickup.set_script(load("res://scripts/item_pickup.gd"))
		pickup.set("item_id", str(supply.id))
		pickup.set("display_name", str(supply.label))
		pickup.set("is_consumable", bool(supply.get("consumable", false)))
		pickup.set("pickup_id", "c%d_%s_%02d" % [chapter_number, str(supply.id), index + 1])
		add_child(pickup)
		var pickup_collision := CollisionShape3D.new()
		var pickup_shape := SphereShape3D.new()
		pickup_shape.radius = 0.85
		pickup_collision.shape = pickup_shape
		pickup.add_child(pickup_collision)
		var marker := MeshInstance3D.new()
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.45, 0.45, 0.45)
		marker.mesh = marker_mesh
		marker.material_override = MAT_ALERT if str(supply.id) in ["kit_estanca", "gas_mask", "omega_master_card"] else MAT_FLOOR
		pickup.add_child(marker)

func _build_hide_spots() -> void:
	for index in range(2):
		var base_position := Vector3(-6.0 if index == 0 else 6.0, 1.1, 13.0 - float(index) * 8.0)
		# The locker is a real solid obstacle, not just a decorative mesh.
		var cover := StaticBody3D.new()
		cover.name = "HideCover_Locker_%d" % index
		cover.position = base_position
		add_child(cover)
		var cover_collision := CollisionShape3D.new()
		var cover_shape := BoxShape3D.new()
		cover_shape.size = Vector3(1.5, 2.2, 1.35)
		cover_collision.shape = cover_shape
		cover.add_child(cover_collision)
		var cover_mesh := MeshInstance3D.new()
		var cover_box := BoxMesh.new()
		cover_box.size = cover_shape.size
		cover_mesh.mesh = cover_box
		cover_mesh.material_override = MAT_WALL
		cover.add_child(cover_mesh)

		# Interaction zone sits in front of the solid locker, reachable by the player ray.
		var spot := Area3D.new()
		spot.name = "HideSpot_Locker_%d" % index
		spot.position = base_position + Vector3(0, 0, 1.25)
		spot.set_script(load("res://scripts/hide_spot.gd"))
		add_child(spot)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.8, 2.2, 1.0)
		collision.shape = shape
		spot.add_child(collision)


func _add_puzzle_station(id: String, label: String, instructions: String, choices: Array[String], solution: Array[String], position: Vector3, flag: String = "", required_items: Dictionary = {}) -> void:
	var station := Area3D.new()
	station.name = "PuzzleStation_" + id
	station.position = position
	station.set_script(load("res://scripts/puzzle_station.gd"))
	station.set("puzzle_id", id)
	station.set("title", label)
	station.set("instructions", instructions)
	station.set("choices", choices)
	station.set("solution", solution)
	station.set("success_flag", flag)
	station.set("required_items", required_items)
	add_child(station)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.2, 1.5)
	collision.shape = shape
	station.add_child(collision)
	var marker := Label3D.new()
	marker.text = label
	marker.position = Vector3(0, 1.6, 0)
	marker.font_size = 30
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color(0.45, 0.95, 0.9)
	station.add_child(marker)

func _build_chapter_puzzle_stations() -> void:
	match chapter_number:
		1:
			_add_puzzle_station("medical_pin", "FECHADURA 0719", "Use a anotação encontrada na triagem.", ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"], ["0", "7", "1", "9"], Vector3(-6.5, 1.0, -10.0), "", {"pin_note_0719":1})
			_add_puzzle_station("medical_relays", "RELÉS MÉDICOS", "Restaure os dois relés identificados no painel.", ["cyan", "amber"], ["cyan", "amber"], Vector3(6.0, 1.0, -10.0), "", {"supervisor_badge":1})
		2:
			_add_puzzle_station("dna_matrix", "MATRIZ DE CALIBRAGEM", "Calibre primeiro o canal Leste e depois o Oeste.", ["east", "west"], ["east", "west"], Vector3(0, 1.0, -8.0), "", {"calibration_chip_east":1, "calibration_chip_west":1})
			_add_puzzle_station("set_flag", "CAMPO DA ALA LESTE", "Use a Chave Dielétrica para desativar o campo magnético.", ["desativar"], ["desativar"], Vector3(6.0, 1.0, 8.0), "east_field_disabled", {"dielectric_key":1})
		3:
			_add_puzzle_station("quarters_pin", "ACESSO DOS ALOJAMENTOS 0315", "Use o código encontrado nos registros de psicologia.", ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"], ["0", "3", "1", "5"], Vector3(-6.0, 1.0, 12.0))
			_add_puzzle_station("therapy_melody", "TERAPIA SONORA", "Reproduza a gravação: Dó, Mi, Sol, Ré, Lá.", ["C", "E", "G", "D", "A"], ["C", "E", "G", "D", "A"], Vector3(0, 1.0, 4.0))
			_add_puzzle_station("set_flag", "LEITOR DE CHIP ALFA", "Sincronize o Chip Alpha e instale o módulo do Tricorder.", ["sincronizar"], ["sincronizar"], Vector3(-6.0, 1.0, -18.0), "alpha_chip_recovered", {"alpha_chip":1, "tricorder_upgrade":1})
		4:
			_add_puzzle_station("set_flag", "DRENAGEM DE AMÔNIA", "Equipe a Máscara de Gás e abra a linha de purga.", ["drenar"], ["drenar"], Vector3(0, 1.0, 8.0), "ammonia_fog_drained", {"gas_mask":1})
			_add_puzzle_station("synthesis_recipe", "BANCADA DE SÍNTESE", "Misture Nitro-Estéril ×2, Ácido Tampão ×1 e Enzima ×3 nessa ordem.", ["nitro", "acid", "enzyme"], ["nitro", "nitro", "acid", "enzyme", "enzyme", "enzyme"], Vector3(0, 1.0, -2.0), "", {"nitro_sterile":2, "acid_buffer":1, "enzyme":3})
			_add_puzzle_station("genesis_valves", "GALERIA DE VÁLVULAS", "Ordem de fluxo: Azul → Verde → Vermelha.", ["blue", "green", "red"], ["blue", "green", "red"], Vector3(0, 1.0, -18.0))
			_add_puzzle_station("set_flag", "CHIP BETA", "Sincronize o Chip Beta recuperado no compartimento drenado.", ["recuperar"], ["recuperar"], Vector3(6.0, 1.0, -25.0), "beta_chip_recovered", {"beta_chip":1})
		5:
			_add_puzzle_station("reactor_shutdown", "PROCEDIMENTO DO REATOR", "Apague as luzes e opere os braços: esquerdo, central, direito.", ["lights_off", "arm_left", "arm_center", "arm_right"], ["lights_off", "arm_left", "arm_center", "arm_right"], Vector3(0, 1.0, -12.0))
			_add_puzzle_station("robot_arms", "CONTROLE DOS BRAÇOS", "Opere os braços na ordem: esquerdo, central, direito.", ["left", "center", "right"], ["left", "center", "right"], Vector3(6.0, 1.0, 10.0))
			_add_puzzle_station("set_flag", "ARCO ELÉTRICO", "Use o arco elétrico para cegar o Newborn.", ["disparar"], ["disparar"], Vector3(6.0, 1.0, 2.0), "electric_arc_used", {"electric_arc":1})
			_add_puzzle_station("set_flag", "COFRE GAMA", "Sincronize o Chip Gamma após estabilizar o núcleo.", ["retirar"], ["retirar"], Vector3(-6.0, 1.0, -25.0), "gamma_chip_recovered", {"gamma_chip":1})
			_add_puzzle_station("set_flag", "PEDESTAL DE CHIPS", "Insira os Chips Beta e Gamma para estabilizar a saída.", ["inserir"], ["inserir"], Vector3(0, 1.0, -30.0), "core_chips_inserted", {"beta_chip":1, "gamma_chip":1})
		6:
			_add_puzzle_station("omega_biochips", "MATRIZ EVOLUTIVA", "Ordene os estágios: Celular, Esquelético, Neural, Despertar.", ["cellular", "skeletal", "neural", "awakening"], ["cellular", "skeletal", "neural", "awakening"], Vector3(0, 1.0, -14.0))
			_add_puzzle_station("omega_download", "DOWNLOAD ÔMEGA", "Inicie a extração. O terminal precisa de 20 segundos sem interrupção.", ["iniciar"], ["iniciar"], Vector3(6.0, 1.0, -24.0))
			_add_puzzle_station("set_flag", "CARTÃO MESTRE ÔMEGA", "Valide o Cartão Mestre Ômega recolhido.", ["retirar"], ["retirar"], Vector3(-6.0, 1.0, -27.0), "omega_master_card_recovered", {"omega_master_card":1})
			_add_puzzle_station("omega_siege", "CERCO ÔMEGA — 75 SEGUNDOS", "Use duas baterias e atravesse as quatro passagens na ordem Norte, Leste, Sul, Oeste. Sobreviva ao cerco.", ["north", "east", "south", "west"], ["north", "east", "south", "west"], Vector3(0, 1.0, -30.0), "", {"battery":2})
		7:
			_add_puzzle_station("hangar_couplings", "ACOPLAMENTOS HIDRÁULICOS", "Conecte os três acoplamentos na ordem 1, 2 e 3.", ["1", "2", "3"], ["1", "2", "3"], Vector3(0, 1.0, -8.0))
			_add_puzzle_station("set_flag", "LEITOR ÔMEGA", "Insira o Cartão Mestre Ômega recuperado no Berçário.", ["inserir"], ["inserir"], Vector3(-6.0, 1.0, -25.0), "omega_card_inserted", {"omega_master_card":1})
			_add_puzzle_station("hangar_override", "CABINE OVERRIDE", "Valide os três acoplamentos e o Cartão Mestre Ômega para liberar o hangar.", ["validar", "override"], ["validar", "override"], Vector3(6.0, 1.0, -25.0))
			_add_puzzle_station("set_flag", "SELAMENTO EXTERNO", "Acione o selo manual e alcance a superfície.", ["selar"], ["selar"], Vector3(0, 1.0, -32.0), "surface_escape_complete")

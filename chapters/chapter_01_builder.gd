extends Node3D
## Modular medical-sector blockout for Chapter 1.

const WALL_MAT := preload("res://materials/medical_wall.tres")
const FLOOR_MAT := preload("res://materials/medical_floor.tres")
const RED_MAT := preload("res://materials/emergency_red.tres")

func _ready() -> void:
	_build_corridor()
	_build_triage()
	_build_signage()
	_spawn_pickups()

func _box(label: String, pos: Vector3, size: Vector3, material: Material, solid: bool = true) -> void:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = label
	body.position = pos
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)

func _build_corridor() -> void:
	_box("Piso_Corredor", Vector3(0, -0.15, 0), Vector3(7, 0.3, 30), FLOOR_MAT)
	_box("Teto_Corredor", Vector3(0, 3.2, 0), Vector3(7, 0.25, 30), WALL_MAT)
	_box("Parede_Esquerda", Vector3(-3.6, 1.5, 0), Vector3(0.25, 3, 30), WALL_MAT)
	_box("Parede_Direita", Vector3(3.6, 1.5, 0), Vector3(0.25, 3, 30), WALL_MAT)
	for i in range(5):
		var z := -12.0 + float(i) * 6.0
		_box("Viga_Estrutural_%02d" % i, Vector3(0, 2.95, z), Vector3(7, 0.28, 0.35), WALL_MAT)
		_box("Painel_Parede_E_%02d" % i, Vector3(-3.43, 1.9, z + 2.0), Vector3(0.08, 0.8, 1.8), FLOOR_MAT, false)
		_box("Painel_Parede_D_%02d" % i, Vector3(3.43, 1.9, z + 2.0), Vector3(0.08, 0.8, 1.8), FLOOR_MAT, false)
	_box("Porta_Acesso_Atrio", Vector3(0, 1.45, -14.7), Vector3(2.4, 2.9, 0.35), RED_MAT)

func _build_triage() -> void:
	_box("Balcao_Triagem", Vector3(-1.8, 0.65, 1.5), Vector3(2.2, 1.3, 0.8), WALL_MAT)
	_box("Armario_Medico", Vector3(2.6, 1.15, -2.0), Vector3(0.75, 2.3, 1.0), FLOOR_MAT)
	_box("Maca_Triagem", Vector3(1.4, 0.55, -6.0), Vector3(1.1, 1.1, 2.4), WALL_MAT)
	_box("Console_Reles", Vector3(-2.9, 1.35, -9.0), Vector3(0.18, 1.4, 1.6), RED_MAT, false)
	for i in range(5):
		_box("Duto_Teto_%02d" % i, Vector3(0, 2.72, -10.0 + float(i) * 4.5), Vector3(1.15, 0.35, 3.2), FLOOR_MAT, false)

func _build_signage() -> void:
	_box("Placa_Ala_Medica", Vector3(-3.43, 2.55, 8.0), Vector3(0.06, 0.55, 2.0), RED_MAT, false)
	_box("Placa_Triagem", Vector3(3.43, 2.55, -4.0), Vector3(0.06, 0.55, 1.6), RED_MAT, false)
	for z in [8.0, -5.0]:
		_box("Luminaria_Emergencia", Vector3(0, 2.88, z), Vector3(1.4, 0.12, 0.28), RED_MAT, false)

func _spawn_pickups() -> void:
	_spawn_pickup("Kit Estanca", "kit_estanca", Vector3(-1.8, 1.35, 1.4), true)
	_spawn_pickup("Crachá Supervisor", "cracha_supervisor", Vector3(1.1, 1.25, -5.5), false)

func _spawn_pickup(label: String, item_id: String, pos: Vector3, consumable: bool) -> void:
	var pickup := Area3D.new()
	pickup.name = "Pickup_" + item_id
	pickup.position = pos
	pickup.set_script(load("res://scripts/item_pickup.gd"))
	pickup.set("item_id", item_id)
	pickup.set("display_name", label)
	pickup.set("is_consumable", consumable)
	add_child(pickup)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.12, 0.2)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = RED_MAT if consumable else FLOOR_MAT
	pickup.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.65, 0.5, 0.65)
	collision.shape = shape
	pickup.add_child(collision)

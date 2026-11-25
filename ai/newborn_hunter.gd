extends CharacterBody3D
class_name NewbornHunter

enum State { OBSERVE, PATROL, INVESTIGATE, HUNT, STUNNED, MIMIC_AMBUSH }
@export var move_speed := 2.4
@export var hunt_speed := 4.2
@export var hearing_radius := 18.0
@export var forget_seconds := 5.0
@export var stun_seconds := 4.5
@export var mimic_enabled := false
@export var patrol_points: Array[Vector3] = []

var eyes: RayCast3D
var navigation: NavigationAgent3D
@onready var face_veins: MeshInstance3D = get_node_or_null("FaceVeins")

var state: State = State.PATROL
var target: Node3D
var last_known_position := Vector3.ZERO
var lost_timer := 0.0
var stun_timer := 0.0
var patrol_index := 0
var attack_cooldown := 0.0
var _repath_timer := 0.0
var _investigate_timer := 0.0
var _organic_head: Node3D
var _lower_jaw: Node3D
var _organic_veins: Array[MeshInstance3D] = []
var _horror_clock := 0.0

func _ready() -> void:
	add_to_group("noise_listeners")
	_build_organic_body()
	eyes = get_node_or_null("EyesRay") as RayCast3D
	if eyes == null:
		eyes = RayCast3D.new()
		eyes.name = "EyesRay"
		eyes.target_position = Vector3(0, 0, -22)
		eyes.enabled = true
		add_child(eyes)
	if navigation == null:
		navigation = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	if navigation == null:
		navigation = NavigationAgent3D.new()
		navigation.name = "NavigationAgent3D"
		add_child(navigation)
	target = get_tree().get_first_node_in_group("player") as Node3D
	# Chapters 3+ use the observation entry state so the mimic ambush is reachable.
	state = State.OBSERVE if mimic_enabled else State.PATROL
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector3(5, 0, 0), global_position + Vector3(5, 0, 7), global_position + Vector3(-4, 0, 7)]
	navigation.path_desired_distance = 0.45
	navigation.target_desired_distance = 0.7
	navigation.avoidance_enabled = true

func hear_noise(origin: Vector3, strength: float) -> void:
	if state == State.STUNNED or state == State.HUNT:
		return
	if global_position.distance_to(origin) <= hearing_radius * clampf(strength, 0.1, 1.5):
		last_known_position = origin
		state = State.INVESTIGATE
		_investigate_timer = 8.0

func stun(seconds: float = 4.5) -> void:
	stun_timer = maxf(seconds, stun_seconds)
	state = State.STUNNED
	velocity = Vector3.ZERO

func _process(delta: float) -> void:
	_horror_clock += delta
	if is_instance_valid(_organic_head):
		var threat := 1.0 if state in [State.HUNT, State.MIMIC_AMBUSH] else 0.25
		_organic_head.rotation.z = sin(_horror_clock * (9.0 + threat * 8.0)) * 0.045 * threat
		_organic_head.rotation.x = sin(_horror_clock * 5.3) * 0.025
	if is_instance_valid(_lower_jaw):
		var jaw_open := 0.32 if state == State.HUNT else 0.02
		_lower_jaw.rotation.x = lerpf(_lower_jaw.rotation.x, jaw_open + sin(_horror_clock * 17.0) * 0.025, delta * 5.0)
	var pulse := 0.5 + 0.5 * sin(_horror_clock * 5.4)
	for vein in _organic_veins:
		var material := vein.material_override as StandardMaterial3D
		if material != null:
			material.emission_energy_multiplier = 0.35 + pulse * (1.25 if state == State.HUNT else 0.55)

func _build_organic_body() -> void:
	var old_body := get_node_or_null("Body") as MeshInstance3D
	if old_body != null:
		old_body.visible = false
	var old_veins := get_node_or_null("Body/FaceVeins") as MeshInstance3D
	if old_veins != null:
		old_veins.visible = false
	var model_path := "res://assets/models/newborn.glb"
	if ResourceLoader.exists(model_path):
		var imported := load(model_path) as PackedScene
		if imported != null:
			var imported_model := imported.instantiate()
			imported_model.name = "ImportedNewbornGLB"
			add_child(imported_model)
			if imported_model is Node3D:
				imported_model.position = Vector3(0, 0, 0)
			var animation_player := imported_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if animation_player != null:
				var animation_names := animation_player.get_animation_list()
				if not animation_names.is_empty():
					animation_player.play(animation_names[0])
			return
	var porcelain := _organic_material(Color(0.72, 0.68, 0.62), 0.22, 0.0)
	var shadow := _organic_material(Color(0.075, 0.055, 0.06), 0.48, 0.0)
	var vein_material := _organic_material(Color(0.19, 0.012, 0.035), 0.3, 0.8)
	var torso := _organic_sphere("PorcelainTorso", Vector3(0, 1.22, 0), Vector3(0.34, 0.76, 0.23), porcelain)
	torso.rotation.z = -0.08
	_organic_sphere("RibCageLeft", Vector3(-0.2, 1.38, -0.12), Vector3(0.11, 0.43, 0.14), shadow).rotation.z = -0.28
	_organic_sphere("RibCageRight", Vector3(0.2, 1.38, -0.12), Vector3(0.11, 0.43, 0.14), shadow).rotation.z = 0.28
	_organic_sphere("Pelvis", Vector3(0, 0.66, 0), Vector3(0.31, 0.23, 0.2), porcelain)
	_organic_limb("LeftArm", Vector3(-0.3, 1.55, 0), Vector3(-0.48, 0.78, -0.08), 0.105, porcelain)
	_organic_limb("RightArm", Vector3(0.3, 1.55, 0), Vector3(0.48, 0.78, -0.08), 0.105, porcelain)
	_organic_limb("LeftLeg", Vector3(-0.17, 0.62, 0), Vector3(-0.2, 0.08, -0.04), 0.14, porcelain)
	_organic_limb("RightLeg", Vector3(0.17, 0.62, 0), Vector3(0.2, 0.08, -0.04), 0.14, porcelain)
	_organic_head = Node3D.new()
	_organic_head.name = "SealedSkull"
	_organic_head.position = Vector3(0, 2.0, -0.015)
	add_child(_organic_head)
	_organic_sphere("Skull", Vector3.ZERO, Vector3(0.29, 0.36, 0.27), porcelain, _organic_head)
	_organic_sphere("SealedMouth", Vector3(0, -0.2, -0.21), Vector3(0.19, 0.065, 0.055), shadow, _organic_head)
	_lower_jaw = Node3D.new()
	_lower_jaw.name = "DoubleJaw"
	_lower_jaw.position = Vector3(0, -0.22, -0.17)
	_organic_head.add_child(_lower_jaw)
	_organic_sphere("JawPlate", Vector3(0, -0.055, -0.08), Vector3(0.2, 0.075, 0.12), shadow, _lower_jaw)
	for side in [-1.0, 1.0]:
		var vein := _organic_sphere("PulsingVein", Vector3(side * 0.14, 1.25, -0.225), Vector3(0.035, 0.48, 0.025), vein_material)
		vein.rotation.z = side * -0.22
		_organic_veins.append(vein)
		var neck_vein := _organic_sphere("NeckVein", Vector3(side * 0.08, 1.82, -0.18), Vector3(0.025, 0.22, 0.025), vein_material)
		neck_vein.rotation.z = side * 0.35
		_organic_veins.append(neck_vein)

func _organic_material(color: Color, roughness: float, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	material.rim_enabled = true
	material.rim = 0.32
	material.rim_tint = 0.28
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = Color(0.55, 0.008, 0.045)
		material.emission_energy_multiplier = emission_energy
	return material

func _organic_sphere(label: String, position: Vector3, scale_value: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = label
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_node.mesh = sphere
	mesh_node.scale = scale_value
	mesh_node.position = position
	mesh_node.material_override = material
	(parent if parent != null else self).add_child(mesh_node)
	return mesh_node

func _organic_limb(label: String, start: Vector3, finish: Vector3, radius: float, material: Material) -> void:
	var delta := finish - start
	var limb := _organic_sphere(label, (start + finish) * 0.5, Vector3(radius, delta.length() * 0.62, radius), material)
	limb.look_at(finish, Vector3.UP)
	limb.rotate_object_local(Vector3.RIGHT, PI * 0.5)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node3D
		return
	if state == State.STUNNED:
		stun_timer -= delta
		_update_telemetry(1000.0)
		if stun_timer <= 0.0:
			state = State.INVESTIGATE
			_investigate_timer = 3.5
		return
	if _target_flag("in_safe_room") or (target.has_method("is_hidden") and target.is_hidden()):
		if state == State.HUNT:
			state = State.PATROL
		velocity.x = move_toward(velocity.x, 0.0, hunt_speed)
		velocity.z = move_toward(velocity.z, 0.0, hunt_speed)
		move_and_slide()
		return
	var distance := global_position.distance_to(target.global_position)
	var visible := _can_see_target(distance)
	_update_telemetry(distance)
	if visible:
		state = State.HUNT
		last_known_position = target.global_position
		lost_timer = 0.0
	elif state == State.HUNT:
		lost_timer += delta
		if lost_timer >= forget_seconds:
			state = State.INVESTIGATE
			_investigate_timer = 6.0
			lost_timer = 0.0
	if mimic_enabled and state == State.OBSERVE and distance < 8.0:
		state = State.MIMIC_AMBUSH
	if state == State.MIMIC_AMBUSH:
		last_known_position = target.global_position
		if distance < 2.0:
			state = State.HUNT
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		match state:
			State.PATROL, State.OBSERVE:
				navigation.target_position = patrol_points[patrol_index]
			State.INVESTIGATE:
				navigation.target_position = last_known_position
			State.HUNT, State.MIMIC_AMBUSH:
				navigation.target_position = target.global_position
		_repath_timer = 0.35 if state == State.HUNT else 0.8
	if navigation.is_navigation_finished() and state == State.PATROL:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		navigation.target_position = patrol_points[patrol_index]
	elif state == State.INVESTIGATE:
		_investigate_timer -= delta
		if _investigate_timer <= 0.0 or global_position.distance_to(last_known_position) < 1.0:
			state = State.PATROL
	var next_position := navigation.get_next_path_position()
	var flat := next_position - global_position
	flat.y = 0.0
	if flat.length() > 0.12:
		var speed := hunt_speed if state in [State.HUNT, State.MIMIC_AMBUSH] else move_speed
		velocity.x = flat.normalized().x * speed
		velocity.z = flat.normalized().z * speed
		look_at(Vector3(next_position.x, global_position.y, next_position.z), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if global_position.distance_to(target.global_position) < 1.15 and attack_cooldown <= 0.0 and state == State.HUNT:
		if target.has_method("take_hit"):
			target.take_hit()
		attack_cooldown = 3.2

func _can_see_target(distance: float) -> bool:
	if _target_flag("in_safe_room") or (target.has_method("is_hidden") and target.is_hidden()):
		return false
	var player_flashlight := _target_flag("flashlight_on") and float(target.get("flashlight_charge")) > 0.0
	var range_limit := 22.0 if player_flashlight else (12.0 if _is_in_lit_room() else 2.0)
	if distance > range_limit:
		return false
	var eye_position := global_position + Vector3.UP * 1.4
	var player_position := target.global_position + Vector3.UP * 1.45
	var to_player := (player_position - eye_position).normalized()
	if (-global_basis.z).dot(to_player) < cos(deg_to_rad(25.0)):
		return false
	var query := PhysicsRayQueryParameters3D.create(eye_position, player_position)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and (hit.collider == target or target.is_ancestor_of(hit.collider))

func _is_in_lit_room() -> bool:
	for light_zone in get_tree().get_nodes_in_group("lit_zone"):
		if light_zone is Node3D and global_position.distance_to(light_zone.global_position) <= 8.0:
			return true
	return false

func _update_telemetry(distance: float) -> void:
	if face_veins == null:
		return
	var material := face_veins.get_active_material(0) as StandardMaterial3D
	if material == null:
		return
	if state == State.HUNT:
		material.albedo_color = Color(0.8, 0.015, 0.08)
		material.emission = Color(0.65, 0.0, 0.04)
	elif distance < 8.0:
		material.albedo_color = Color(0.05, 0.8, 0.95)
		material.emission = Color(0.0, 0.45, 0.75)
	else:
		material.albedo_color = Color(0.015, 0.02, 0.025)
		material.emission = Color.BLACK

func _target_flag(property_name: String) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var value: Variant = target.get(property_name)
	return value is bool and value

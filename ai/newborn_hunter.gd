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

@onready var eyes: RayCast3D = $EyesRay
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

func _ready() -> void:
	add_to_group("noise_listeners")
	if navigation == null:
		navigation = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	if navigation == null:
		navigation = NavigationAgent3D.new()
		navigation.name = "NavigationAgent3D"
		add_child(navigation)
	target = get_tree().get_first_node_in_group("player") as Node3D
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

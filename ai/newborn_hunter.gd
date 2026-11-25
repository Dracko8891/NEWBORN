extends CharacterBody3D
class_name NewbornHunter

enum State { DORMANT, PATROL, INVESTIGATE, SEARCH, CHASE, STUNNED, RETURN }
@export var move_speed := 2.4
@export var chase_speed := 4.2
@export var hearing_radius := 18.0
@export var sight_distance := 13.0
@export var sight_angle_degrees := 72.0
@export var forget_seconds := 5.0
@onready var eyes: RayCast3D = get_node_or_null("EyesRay")
var state: State = State.PATROL
var target: Node3D
var last_known_position := Vector3.ZERO
var lost_timer := 0.0
var search_timer := 0.0
var stun_timer := 0.0
var patrol_points: Array[Vector3] = []
var patrol_index := 0
var attack_cooldown := 0.0

func _ready() -> void:
	add_to_group("noise_listeners")
	target = get_tree().get_first_node_in_group("player") as Node3D
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector3(5, 0, 0), global_position + Vector3(5, 0, 7), global_position + Vector3(-4, 0, 7)]

func hear_noise(origin: Vector3, strength: float) -> void:
	if state == State.STUNNED or state == State.CHASE:
		return
	if global_position.distance_to(origin) <= hearing_radius * clampf(strength, 0.1, 1.5):
		last_known_position = origin
		state = State.INVESTIGATE

func stun(seconds: float = 4.5) -> void:
	stun_timer = seconds
	state = State.STUNNED
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node3D
		return
	if state == State.STUNNED:
		stun_timer -= delta
		if stun_timer <= 0.0:
			state = State.SEARCH
			search_timer = 3.5
		return
	if bool(target.get("in_safe_room")):
		state = State.PATROL
		lost_timer = 0.0
		search_timer = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var distance := global_position.distance_to(target.global_position)
	var visible := _can_see_target(distance)
	if visible:
		state = State.CHASE
		last_known_position = target.global_position
		lost_timer = 0.0
	elif state == State.CHASE:
		lost_timer += delta
		if lost_timer >= forget_seconds:
			state = State.SEARCH
			lost_timer = 0.0
	var destination := global_position
	match state:
		State.PATROL:
			destination = patrol_points[patrol_index]
			if global_position.distance_to(destination) < 0.8:
				patrol_index = (patrol_index + 1) % patrol_points.size()
		State.INVESTIGATE:
			destination = last_known_position
			if global_position.distance_to(destination) < 1.0:
				state = State.SEARCH
				search_timer = 3.5
		State.SEARCH:
			destination = last_known_position
			search_timer = maxf(0.0, search_timer - delta)
			if search_timer <= 0.0:
				state = State.PATROL
		State.CHASE:
			destination = target.global_position
		_:
			pass
	var flat := destination - global_position
	flat.y = 0.0
	if flat.length() > 0.15:
		velocity.x = flat.normalized().x * (chase_speed if state == State.CHASE else move_speed)
		velocity.z = flat.normalized().z * (chase_speed if state == State.CHASE else move_speed)
		look_at(Vector3(destination.x, global_position.y, destination.z), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if global_position.distance_to(target.global_position) < 1.15 and attack_cooldown <= 0.0 and state == State.CHASE and not (target.has_method("is_hidden") and target.is_hidden()) and not bool(target.get("in_safe_room")):
		if target.has_method("take_hit"):
			target.take_hit()
		attack_cooldown = 3.2

func _can_see_target(distance: float) -> bool:
	if bool(target.get("in_safe_room")):
		return false
	if distance > sight_distance:
		return false
	if target.has_method("is_hidden") and target.is_hidden():
		return false
	var to_target := (target.global_position + Vector3.UP * 0.8 - global_position).normalized()
	var forward := -global_transform.basis.z
	if rad_to_deg(forward.angle_to(to_target)) > sight_angle_degrees * 0.5:
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.4, target.global_position + Vector3.UP * 0.8)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target

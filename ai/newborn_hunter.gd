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
var _path_grid := AStarGrid2D.new()
var _path_points: Array[Vector3] = []
var _path_index := 0
var _path_refresh := 0.0
var _path_valid := false
var _path_shape := BoxShape3D.new()

func _ready() -> void:
	add_to_group("noise_listeners")
	target = get_tree().get_first_node_in_group("player") as Node3D
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector3(5, 0, 0), global_position + Vector3(5, 0, 7), global_position + Vector3(-4, 0, 7)]
	_path_shape.size = Vector3(0.72, 1.5, 0.72)
	_path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

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
	_path_refresh -= delta
	if _path_refresh <= 0.0:
		var goal := target.global_position if state == State.CHASE else last_known_position
		if state == State.PATROL:
			goal = patrol_points[patrol_index]
		_refresh_path(goal)
		_path_refresh = 1.0
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
	if not _path_valid:
		# Fail closed: never steer directly toward a target when A* found no safe route.
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= 18.0 * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return
	if not _path_points.is_empty():
		while _path_index < _path_points.size() - 1 and global_position.distance_to(_path_points[_path_index]) < 0.48:
			_path_index += 1
		destination = _path_points[_path_index]
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
	# No hit is not proof of visibility: fail closed unless the first collider is the player.
	return not hit.is_empty() and hit.get("collider") == target

# Rebuild a local 1 m navigation grid from real physics occupancy.
func _refresh_path(goal: Vector3) -> void:
	_path_valid = false
	_path_points.clear()
	_path_index = 0
	var start_cell := Vector2i(floori(global_position.x), floori(global_position.z))
	var goal_cell := Vector2i(floori(goal.x), floori(goal.z))
	var min_x := maxi(-9, mini(start_cell.x, goal_cell.x) - 5)
	var min_z := maxi(-35, mini(start_cell.y, goal_cell.y) - 5)
	var max_x := mini(9, maxi(start_cell.x, goal_cell.x) + 6)
	var max_z := mini(35, maxi(start_cell.y, goal_cell.y) + 6)
	if max_x <= min_x or max_z <= min_z:
		return
	_path_grid.region = Rect2i(min_x, min_z, max_x - min_x, max_z - min_z)
	_path_grid.cell_size = Vector2.ONE
	_path_grid.update()
	var exclude_rids: Array[RID] = [get_rid()]
	if target is CollisionObject3D:
		exclude_rids.append((target as CollisionObject3D).get_rid())
	var space := get_world_3d().direct_space_state
	for z in range(min_z, max_z):
		for x in range(min_x, max_x):
			var cell := Vector2i(x, z)
			# Ignore only the hunter's occupied start cell; the goal must also
			# pass the physical occupancy query so a closed door cannot be treated as open.
			if cell == start_cell:
				continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = _path_shape
			query.transform = Transform3D(Basis.IDENTITY, Vector3(float(x) + 0.5, 0.82, float(z) + 0.5))
			query.exclude = exclude_rids
			query.collision_mask = collision_mask
			if not space.intersect_shape(query, 1).is_empty():
				_path_grid.set_point_solid(cell, true)
	if not _path_grid.is_in_boundsv(start_cell) or not _path_grid.is_in_boundsv(goal_cell):
		_path_points.clear()
		_path_index = 0
		return
	var ids := _path_grid.get_id_path(start_cell, goal_cell)
	if ids.is_empty():
		return
	for i in range(1, ids.size()):
		var cell: Vector2i = ids[i]
		_path_points.append(Vector3(float(cell.x) + 0.5, global_position.y, float(cell.y) + 0.5))
	if _path_points.is_empty() and start_cell == goal_cell:
		_path_points.append(Vector3(float(goal_cell.x) + 0.5, global_position.y, float(goal_cell.y) + 0.5))
	_path_valid = not _path_points.is_empty()

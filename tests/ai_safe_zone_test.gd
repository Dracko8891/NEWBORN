extends SceneTree

const HunterScript = preload("res://ai/newborn_hunter.gd")

class MockPlayer:
	extends CharacterBody3D
	var hidden_in_cover: bool = false
	var in_safe_room: bool = false
	var hit_count: int = 0

	func is_hidden() -> bool:
		return hidden_in_cover

	func enter_hide_spot() -> void:
		hidden_in_cover = true
		velocity = Vector3.ZERO

	func leave_hide_spot() -> void:
		hidden_in_cover = false

	func take_hit() -> void:
		hit_count += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	world.name = "HideChasePhysicsTest"
	root.add_child(world)

	# Real floor and solid obstacle participate in the 3D physics server.
	var floor := StaticBody3D.new()
	floor.position = Vector3(0, -0.5, 0)
	world.add_child(floor)
	_add_box_collision(floor, Vector3(30, 1, 30))

	var obstacle := StaticBody3D.new()
	obstacle.name = "LockerObstacle"
	obstacle.position = Vector3(0, 1.5, 0)
	world.add_child(obstacle)
	_add_box_collision(obstacle, Vector3(4.0, 3.0, 0.9))

	var player := MockPlayer.new()
	player.name = "Player"
	player.position = Vector3(0, 0.95, 7.0)
	player.add_to_group("player")
	world.add_child(player)
	_add_capsule_collision(player, 0.32, 1.8)

	var hunter: CharacterBody3D = HunterScript.new()
	hunter.name = "NewbornHunter"
	hunter.position = Vector3(0, 1.1, -7.0)
	world.add_child(hunter)
	_add_capsule_collision(hunter, 0.42, 2.25)
	await physics_frame

	hunter.state = 3 # HUNT
	assert(not hunter._can_see_target(hunter.global_position.distance_to(player.global_position)), "Hunter must not see through the solid locker")
	for frame in range(150):
		await physics_frame
	assert(absf(hunter.global_position.x) > 2.0 or hunter.global_position.z < -0.35, "Hunter must route around the locker instead of crossing through it")
	assert(player.hit_count == 0, "Hunter must not damage the player through the obstacle")

	# Exercise the same hide-state contract used by the actual player controller.
	player.enter_hide_spot()
	assert(player.is_hidden(), "Player should enter the hide state")
	player.global_position = hunter.global_position + Vector3(0, 0, -0.8)
	obstacle.queue_free()
	await physics_frame
	hunter.global_position = player.global_position + Vector3(0, 0, -0.8)
	hunter.state = 3
	hunter.attack_cooldown = 0.0
	await physics_frame
	assert(not hunter._can_see_target(hunter.global_position.distance_to(player.global_position)), "Hunter must not see a hidden player")
	assert(player.hit_count == 0, "Hunter must not attack a player inside a hide spot")

	# Control case: leaving cover restores ordinary detection and attack behavior.
	player.leave_hide_spot()
	player.global_position = hunter.global_position + Vector3(0, 0, 0.8)
	hunter.look_at(player.global_position, Vector3.UP)
	hunter.state = 3
	hunter.attack_cooldown = 0.0
	await physics_frame
	assert(player.hit_count == 1, "Visible, unhidden player at contact range should be attackable")

	# Mimic chapters must actually enter OBSERVE and transition into their ambush state.
	var mimic_hunter: CharacterBody3D = HunterScript.new()
	mimic_hunter.name = "MimicHunter"
	mimic_hunter.set("mimic_enabled", true)
	mimic_hunter.position = player.global_position + Vector3(0, 0, -4.0)
	world.add_child(mimic_hunter)
	_add_capsule_collision(mimic_hunter, 0.42, 2.25)
	assert(int(mimic_hunter.get("state")) == 0, "Mimic hunter must start in OBSERVE")
	await physics_frame
	assert(int(mimic_hunter.get("state")) == 5, "Mimic hunter must transition to MIMIC_AMBUSH when close and unseen")

	print("NEWBORN real physics chase / locker collision / hiding / mimic tests: PASS")
	quit(0)

func _add_box_collision(parent: Node3D, dimensions: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	parent.add_child(collision)

func _add_capsule_collision(parent: Node3D, radius: float, height: float) -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	parent.add_child(collision)

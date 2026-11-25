extends SceneTree

const HunterScript = preload("res://ai/newborn_hunter.gd")

class MockTarget:
	extends Node3D
	var in_safe_room: bool = false
	var hidden_in_cover: bool = false
	var hit_count: int = 0

	func is_hidden() -> bool:
		return hidden_in_cover

	func take_hit() -> void:
		hit_count += 1

func _initialize() -> void:
	var target := MockTarget.new()
	target.name = "TestPlayer"
	target.add_to_group("player")
	root.add_child(target)
	var hunter = HunterScript.new()
	hunter.name = "TestHunter"
	root.add_child(hunter)
	call_deferred("_run", hunter, target)

func _run(hunter: Variant, target: Variant) -> void:
	# A safe-room occupant must immediately break the chase.
	hunter.state = 4 # CHASE
	target.in_safe_room = true
	hunter._physics_process(0.016)
	assert(hunter.state == 1) # PATROL
	assert(target.hit_count == 0)

	# Hiding blocks visual acquisition and contact damage.
	target.in_safe_room = false
	target.hidden_in_cover = true
	hunter.state = 4 # CHASE
	hunter.attack_cooldown = 0.0
	hunter._physics_process(0.016)
	assert(target.hit_count == 0)

	print("NEWBORN hunter safe-room and hiding tests: PASS")
	quit(0)

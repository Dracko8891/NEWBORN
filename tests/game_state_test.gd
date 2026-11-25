extends SceneTree

const GameStateScript = preload("res://systems/game_state.gd")
var game_state: Variant

class MockPlayer:
	extends Node
	var recharged_seconds: float = 0.0

	func recharge_flashlight(amount: float) -> bool:
		recharged_seconds += amount
		return true

func _initialize() -> void:
	game_state = GameStateScript.new()
	root.add_child(game_state)
	call_deferred("_run")

func _run() -> void:
	game_state.inventory.clear()
	game_state.safe_storage.clear()
	game_state.inventory_capacity = game_state.START_SLOTS
	game_state.chapter = 1
	game_state.set_health_state(0)

	# Stack totals and removal across multiple inventory slots.
	assert(game_state.add_item("ammo_test", "Munição de teste", true))
	assert(game_state.add_item("ammo_test", "Munição de teste", true))
	assert(game_state.add_item("ammo_test", "Munição de teste", true))
	assert(game_state.has_item("ammo_test", 3))
	assert(game_state.remove_item("ammo_test", 3))
	assert(not game_state.has_item("ammo_test"))

	# Medical item is consumed only when it can treat bleeding.
	game_state.set_health_state(1)
	assert(game_state.add_item("kit_estanca", "Kit Estanca", true))
	assert(game_state.use_item("kit_estanca"))
	assert(game_state.health_state == 0)
	assert(not game_state.has_item("kit_estanca"))

	# Battery consumable calls the player's flashlight recharge API.
	var mock_player := MockPlayer.new()
	assert(game_state.add_item("battery", "Bateria", true))
	assert(game_state.use_item("battery", mock_player))
	assert(is_equal_approx(mock_player.recharged_seconds, 90.0))
	mock_player.free()

	# Safe storage supports bulk deposit, withdrawal and persistence.
	game_state.set_health_state(1)
	game_state.flashlight_charge_saved = 123.0
	assert(game_state.add_item("keycard_test", "Cartão de teste", false))
	assert(game_state.store_all_items() == 1)
	assert(game_state.inventory.is_empty())
	assert(game_state.safe_storage_count() == 1)
	assert(game_state.save_game())
	game_state.safe_storage.clear()
	game_state.set_health_state(0)
	game_state.flashlight_charge_saved = 0.0
	assert(game_state.load_game())
	assert(game_state.health_state == 1)
	assert(is_equal_approx(game_state.flashlight_charge_saved, 123.0))
	assert(game_state.safe_storage_count() == 1)
	assert(game_state.retrieve_all_items() == 1)
	assert(game_state.has_item("keycard_test"))

	# Leave the test save in a clean state.
	game_state.inventory.clear()
	game_state.safe_storage.clear()
	game_state.set_health_state(0)
	game_state.save_game()
	print("NEWBORN GameState integration tests: PASS")
	quit(0)

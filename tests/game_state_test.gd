extends SceneTree

class MockPlayer:
	extends Node
	var recharged_seconds: float = 0.0

	func recharge_flashlight(amount: float) -> bool:
		recharged_seconds += amount
		return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.inventory.clear()
	GameState.safe_storage.clear()
	GameState.inventory_capacity = GameState.START_SLOTS
	GameState.chapter = 1
	GameState.set_health_state(0)

	# Stack totals and removal across multiple inventory slots.
	assert(GameState.add_item("ammo_test", "Munição de teste", true))
	assert(GameState.add_item("ammo_test", "Munição de teste", true))
	assert(GameState.add_item("ammo_test", "Munição de teste", true))
	assert(GameState.has_item("ammo_test", 3))
	assert(GameState.remove_item("ammo_test", 3))
	assert(not GameState.has_item("ammo_test"))

	# Medical item is consumed only when it can treat bleeding.
	GameState.set_health_state(1)
	assert(GameState.add_item("kit_estanca", "Kit Estanca", true))
	assert(GameState.use_item("kit_estanca"))
	assert(GameState.health_state == 0)
	assert(not GameState.has_item("kit_estanca"))

	# Battery consumable calls the player's flashlight recharge API.
	var mock_player := MockPlayer.new()
	assert(GameState.add_item("battery", "Bateria", true))
	assert(GameState.use_item("battery", mock_player))
	assert(is_equal_approx(mock_player.recharged_seconds, 90.0))
	mock_player.free()

	# Safe storage supports bulk deposit, withdrawal and persistence.
	assert(GameState.add_item("keycard_test", "Cartão de teste", false))
	assert(GameState.store_all_items() == 1)
	assert(GameState.inventory.is_empty())
	assert(GameState.safe_storage_count() == 1)
	assert(GameState.save_game())
	GameState.safe_storage.clear()
	assert(GameState.load_game())
	assert(GameState.safe_storage_count() == 1)
	assert(GameState.retrieve_all_items() == 1)
	assert(GameState.has_item("keycard_test"))

	# Leave the test save in a clean state.
	GameState.inventory.clear()
	GameState.safe_storage.clear()
	GameState.set_health_state(0)
	GameState.save_game()
	print("NEWBORN GameState integration tests: PASS")
	quit(0)

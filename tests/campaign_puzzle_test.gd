extends Node

const Campaign = preload("res://systems/campaign_data.gd")

class MockPlayer:
	extends Node
	var dead: bool = false
	func is_dead() -> bool:
		return dead

func _ready() -> void:
	_run()

func _strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result

func _run() -> void:
	var game_state: Node = GameState
	var puzzle_system: Node = PuzzleSystem
	var campaign_director: Node = CampaignDirector
	game_state.inventory.clear()
	game_state.safe_storage.clear()
	game_state.puzzle_flags.clear()
	game_state.collected_flags.clear()
	campaign_director.objective_done.clear()
	campaign_director.current_objective = 0

	# All seven chapters must expose a title, five objectives and a scene resource.
	for chapter in range(1, 8):
		var chapter_data := Campaign.get_chapter(chapter)
		assert(not chapter_data.is_empty())
		assert(chapter_data.get("objectives", []).size() == 5)
		assert(ResourceLoader.exists("res://chapters/chapter_%02d.tscn" % chapter))

	# Quest pickups remain valid after a consumable is used.
	game_state.chapter = 1
	game_state.collected_flags["chapter_1:c1_kit_estanca_01"] = true
	assert(campaign_director._objective_requirements_met("c1_o1"))
	game_state.collected_flags["chapter_1:c1_supervisor_badge_03"] = true
	game_state.collected_flags["chapter_1:c1_pin_note_0719_04"] = true
	game_state.set_flag("medical_door_unlocked")
	assert(campaign_director._objective_requirements_met("c1_o2"))

	# Chapter 1: wrong PIN/relay sequence must not unlock progression.
	assert(not puzzle_system.submit_pin("0718"))
	assert(puzzle_system.submit_pin("0719"))
	assert(not puzzle_system.submit_relays(_strings(["amber", "blue"])))
	assert(puzzle_system.submit_relays(_strings(["cyan", "amber"])))
	assert(campaign_director._objective_requirements_met("c1_o3"))
	assert(campaign_director._objective_requirements_met("c1_o4"))

	# Chapter 2: both matrix channels must be calibrated in the documented order.
	assert(not puzzle_system.submit_dna_matrix(_strings(["west", "east"])))
	assert(puzzle_system.submit_dna_matrix(_strings(["east", "west"])))
	assert(campaign_director._objective_requirements_met("c2_o2"))

	# Chapter 3 and 4: exact melody and valve order.
	assert(not puzzle_system.submit_melody(_strings(["C", "G", "E", "D", "A"])))
	assert(puzzle_system.submit_melody(_strings(["C", "E", "G", "D", "A"])))
	assert(puzzle_system.submit_valves(_strings(["blue", "red", "green"])) == false)
	assert(puzzle_system.submit_valves(_strings(["blue", "green", "red"])))
	assert(campaign_director._objective_requirements_met("c3_o3"))
	assert(campaign_director._objective_requirements_met("c4_o4"))

	# Chapter 5: reactor shutdown requires all four ordered operations.
	assert(not puzzle_system.submit_reactor_shutdown(_strings(["arm_left", "lights_off", "arm_center", "arm_right"])))
	assert(puzzle_system.submit_reactor_shutdown(_strings(["lights_off", "arm_left", "arm_center", "arm_right"])))
	assert(campaign_director._objective_requirements_met("c5_o2"))
	assert(not puzzle_system.submit_robot_arms(_strings(["center", "left", "right"])))
	assert(puzzle_system.submit_robot_arms(_strings(["left", "center", "right"])))
	assert(campaign_director._objective_requirements_met("c5_o3"))
	assert(not puzzle_system.submit_quarters_pin("0314"))
	assert(puzzle_system.submit_quarters_pin("0315"))
	assert(campaign_director._objective_requirements_met("c3_o1"))

	# Chapter 4: synthesis requires and consumes the exact ingredient quantities.
	var synthesis_station: Node = load("res://scripts/puzzle_station.gd").new()
	synthesis_station.puzzle_id = "synthesis_recipe"
	synthesis_station.required_items = {"nitro_sterile":2, "acid_buffer":1, "enzyme":3}
	synthesis_station.entered = _strings(["nitro", "nitro", "acid", "enzyme", "enzyme", "enzyme"])
	assert(not synthesis_station._commit_puzzle())
	assert(game_state.add_item("nitro_sterile", "Nitro-Estéril", true))
	assert(game_state.add_item("nitro_sterile", "Nitro-Estéril", true))
	assert(game_state.add_item("acid_buffer", "Ácido Tampão", true))
	assert(game_state.add_item("enzyme", "Enzima", true))
	assert(game_state.add_item("enzyme", "Enzima", true))
	assert(game_state.add_item("enzyme", "Enzima", true))
	assert(synthesis_station._commit_puzzle())
	assert(not game_state.has_item("nitro_sterile"))
	assert(not game_state.has_item("acid_buffer"))
	assert(not game_state.has_item("enzyme"))
	game_state.chapter = 4
	assert(campaign_director._objective_requirements_met("c4_o2"))
	game_state.chapter = 1
	synthesis_station.free()

	# Chapter 6: four evolution stages in the correct order.
	assert(not puzzle_system.submit_biochips(_strings(["cellular", "neural", "skeletal", "awakening"])))
	assert(puzzle_system.submit_biochips(_strings(["cellular", "skeletal", "neural", "awakening"])))
	assert(campaign_director._objective_requirements_met("c6_o2"))

	# Chapter 7: the override cannot run until all couplings and the master card exist.
	assert(puzzle_system.activate_hydraulic_coupling(1))
	assert(puzzle_system.activate_hydraulic_coupling(2))
	assert(not puzzle_system.execute_hangar_override())
	assert(puzzle_system.activate_hydraulic_coupling(3))
	assert(game_state.get_flag("hangar_couplings_complete"))
	assert(game_state.add_item("omega_master_card", "Cartão Mestre Ômega", false))
	assert(puzzle_system.execute_hangar_override())
	assert(campaign_director._objective_requirements_met("c7_o4"))

	# A later chapter objective remains blocked until its explicit flag is set.
	assert(not campaign_director._objective_requirements_met("c6_o3"))
	puzzle_system.complete_omega_download()
	assert(campaign_director._objective_requirements_met("c6_o3"))

	game_state.inventory.clear()
	game_state.safe_storage.clear()
	game_state.puzzle_flags.clear()
	game_state.collected_flags.clear()
	game_state.save_game()
	# Exercise the timed siege with a short test duration and verify death interrupts it.
	var mock_player := MockPlayer.new()
	mock_player.add_to_group("player")
	add_child(mock_player)
	var timed_station: Node = load("res://scripts/puzzle_station.gd").new()
	add_child(timed_station)
	timed_station._start_countdown(0.05, "siege")
	var success_check := Timer.new()
	success_check.wait_time = 0.15
	success_check.one_shot = true
	success_check.timeout.connect(_on_siege_success.bind(timed_station, mock_player))
	add_child(success_check)
	success_check.start()

func _on_siege_success(timed_station: Node, mock_player: Node) -> void:
	assert(GameState.get_flag("omega_siege_survived", false))
	GameState.set_flag("omega_siege_survived", false)
	mock_player.dead = true
	timed_station._start_countdown(0.05, "siege")
	var failure_check := Timer.new()
	failure_check.wait_time = 0.15
	failure_check.one_shot = true
	failure_check.timeout.connect(_on_siege_interrupted.bind(timed_station, mock_player))
	add_child(failure_check)
	failure_check.start()

func _on_siege_interrupted(timed_station: Node, mock_player: Node) -> void:
	assert(not GameState.get_flag("omega_siege_survived", false))
	timed_station.queue_free()
	mock_player.queue_free()
	GameState.puzzle_flags.clear()
	GameState.collected_flags.clear()
	GameState.save_game()
	print("NEWBORN chapter puzzle, synthesis and timed siege tests: PASS")
	get_tree().quit()

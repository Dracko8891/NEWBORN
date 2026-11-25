extends Node

func _ready() -> void:
	_run()

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

	# Chapter 1: wrong PIN/relay sequence must not unlock progression.
	assert(not puzzle_system.submit_pin("0718"))
	assert(puzzle_system.submit_pin("0719"))
	assert(not puzzle_system.submit_relays(["amber", "blue"]))
	assert(puzzle_system.submit_relays(["cyan", "amber"]))
	assert(campaign_director._objective_requirements_met("c1_o3"))
	assert(campaign_director._objective_requirements_met("c1_o4"))

	# Chapter 2: both matrix channels must be calibrated in the documented order.
	assert(not puzzle_system.submit_dna_matrix(["west", "east"]))
	assert(puzzle_system.submit_dna_matrix(["east", "west"]))
	assert(campaign_director._objective_requirements_met("c2_o2"))

	# Chapter 3 and 4: exact melody and valve order.
	assert(not puzzle_system.submit_melody(["C", "G", "E", "D", "A"]))
	assert(puzzle_system.submit_melody(["C", "E", "G", "D", "A"]))
	assert(puzzle_system.submit_valves(["blue", "red", "green"]) == false)
	assert(puzzle_system.submit_valves(["blue", "green", "red"]))
	assert(campaign_director._objective_requirements_met("c3_o3"))
	assert(campaign_director._objective_requirements_met("c4_o4"))

	# Chapter 5: reactor shutdown requires all four ordered operations.
	assert(not puzzle_system.submit_reactor_shutdown(["arm_left", "lights_off", "arm_center", "arm_right"]))
	assert(puzzle_system.submit_reactor_shutdown(["lights_off", "arm_left", "arm_center", "arm_right"]))
	assert(campaign_director._objective_requirements_met("c5_o2"))

	# Chapter 6: four evolution stages in the correct order.
	assert(not puzzle_system.submit_biochips(["cellular", "neural", "skeletal", "awakening"]))
	assert(puzzle_system.submit_biochips(["cellular", "skeletal", "neural", "awakening"]))
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
	print("NEWBORN chapter puzzle and progression gate tests: PASS")
	get_tree().quit()

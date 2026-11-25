extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.inventory.clear()
	GameState.safe_storage.clear()
	GameState.puzzle_flags.clear()
	GameState.collected_flags.clear()
	CampaignDirector.objective_done.clear()
	CampaignDirector.current_objective = 0

	# Chapter 1: wrong PIN/relay sequence must not unlock progression.
	assert(not PuzzleSystem.submit_pin("0718"))
	assert(PuzzleSystem.submit_pin("0719"))
	assert(not PuzzleSystem.submit_relays(["amber", "cyan"]))
	assert(PuzzleSystem.submit_relays(["cyan", "amber"]))
	assert(CampaignDirector._objective_requirements_met("c1_o3"))
	assert(CampaignDirector._objective_requirements_met("c1_o4"))

	# Chapter 2: both matrix channels must be calibrated in the documented order.
	assert(not PuzzleSystem.submit_dna_matrix(["west", "east"]))
	assert(PuzzleSystem.submit_dna_matrix(["east", "west"]))
	assert(CampaignDirector._objective_requirements_met("c2_o2"))

	# Chapter 3 and 4: exact melody and valve order.
	assert(not PuzzleSystem.submit_melody(["C", "G", "E", "D", "A"]))
	assert(PuzzleSystem.submit_melody(["C", "E", "G", "D", "A"]))
	assert(PuzzleSystem.submit_valves(["blue", "red", "green"]) == false)
	assert(PuzzleSystem.submit_valves(["blue", "green", "red"]))
	assert(CampaignDirector._objective_requirements_met("c3_o3"))
	assert(CampaignDirector._objective_requirements_met("c4_o4"))

	# Chapter 5: reactor shutdown requires all four ordered operations.
	assert(not PuzzleSystem.submit_reactor_shutdown(["arm_left", "lights_off", "arm_center", "arm_right"]))
	assert(PuzzleSystem.submit_reactor_shutdown(["lights_off", "arm_left", "arm_center", "arm_right"]))
	assert(CampaignDirector._objective_requirements_met("c5_o2"))

	# Chapter 6: four evolution stages in the correct order.
	assert(not PuzzleSystem.submit_biochips(["cellular", "neural", "skeletal", "awakening"]))
	assert(PuzzleSystem.submit_biochips(["cellular", "skeletal", "neural", "awakening"]))
	assert(CampaignDirector._objective_requirements_met("c6_o2"))

	# Chapter 7: the override cannot run until all couplings and the master card exist.
	assert(PuzzleSystem.activate_hydraulic_coupling(1))
	assert(PuzzleSystem.activate_hydraulic_coupling(2))
	assert(not PuzzleSystem.execute_hangar_override())
	assert(PuzzleSystem.activate_hydraulic_coupling(3))
	assert(GameState.add_item("omega_master_card", "Cartão Mestre Ômega", false))
	assert(PuzzleSystem.execute_hangar_override())
	assert(CampaignDirector._objective_requirements_met("c7_o4"))

	# A later chapter objective remains blocked until its explicit flag is set.
	assert(not CampaignDirector._objective_requirements_met("c6_o3"))
	PuzzleSystem.complete_omega_download()
	assert(CampaignDirector._objective_requirements_met("c6_o3"))

	GameState.inventory.clear()
	GameState.safe_storage.clear()
	GameState.puzzle_flags.clear()
	GameState.collected_flags.clear()
	GameState.save_game()
	print("NEWBORN chapter puzzle and progression gate tests: PASS")
	quit(0)

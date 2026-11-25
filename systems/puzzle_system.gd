extends Node

signal puzzle_solved(puzzle_id: String)
signal puzzle_failed(puzzle_id: String, reason: String)
signal hint_requested(message: String)

const RELAY_REQUIRED := ["cyan", "amber"]
const VALVE_REQUIRED := ["blue", "green", "red"]
const BIOCHIP_REQUIRED := ["cellular", "skeletal", "neural", "awakening"]
const MELODY_REQUIRED := ["C", "E", "G", "D", "A"]

func submit_pin(value: String) -> bool:
	if value != "0719":
		puzzle_failed.emit("medical_door", "PIN incorreto")
		return false
	GameState.set_flag("medical_door_unlocked")
	puzzle_solved.emit("medical_door")
	return true

func submit_relays(active_relays: Array[String]) -> bool:
	if not _same_set(active_relays, RELAY_REQUIRED):
		puzzle_failed.emit("medical_relays", "Relés fora da combinação")
		return false
	GameState.set_flag("medical_relays_restored")
	puzzle_solved.emit("medical_relays")
	return true

func submit_melody(notes: Array[String]) -> bool:
	if notes != MELODY_REQUIRED:
		puzzle_failed.emit("therapy_melody", "Sequência musical incorreta")
		return false
	GameState.set_flag("therapy_melody_solved")
	puzzle_solved.emit("therapy_melody")
	return true

func submit_valves(sequence: Array[String]) -> bool:
	if sequence != VALVE_REQUIRED:
		puzzle_failed.emit("genesis_valves", "Ordem das válvulas incorreta")
		return false
	GameState.set_flag("genesis_valves_solved")
	puzzle_solved.emit("genesis_valves")
	return true

func submit_biochips(sequence: Array[String]) -> bool:
	if sequence != BIOCHIP_REQUIRED:
		puzzle_failed.emit("omega_biochips", "Sequência de evolução incorreta")
		return false
	GameState.set_flag("omega_biochips_solved")
	puzzle_solved.emit("omega_biochips")
	return true

func activate_hydraulic_coupling(index: int) -> bool:
	if index < 1 or index > 3:
		return false
	var couplings: Array = GameState.puzzle_flags.get("hangar_couplings", [false, false, false])
	couplings[index - 1] = true
	GameState.set_flag("hangar_couplings", couplings)
	if couplings.all(func(value: Variant) -> bool: return bool(value)):
		puzzle_solved.emit("hangar_hydraulics")
	return true

func _same_set(a: Array[String], b: Array[String]) -> bool:
	if a.size() != b.size():
		return false
	for value in a:
		if not b.has(value):
			return false
	return true


func submit_dna_matrix(sequence: Array[String]) -> bool:
	if sequence != ["east", "west"]:
		puzzle_failed.emit("dna_matrix", "Calibração exige Leste e depois Oeste")
		return false
	GameState.set_flag("dna_matrix_calibrated")
	puzzle_solved.emit("dna_matrix")
	GameState.save_game()
	return true

func submit_reactor_shutdown(sequence: Array[String]) -> bool:
	if sequence != ["lights_off", "arm_left", "arm_center", "arm_right"]:
		puzzle_failed.emit("reactor_shutdown", "Procedimento de desligamento inválido")
		return false
	GameState.set_flag("reactor_shutdown_complete")
	puzzle_solved.emit("reactor_shutdown")
	GameState.save_game()
	return true

func complete_omega_download() -> void:
	GameState.set_flag("omega_download_complete")
	puzzle_solved.emit("omega_download")
	GameState.save_game()

func survive_omega_siege() -> void:
	GameState.set_flag("omega_siege_survived")
	puzzle_solved.emit("omega_siege")
	GameState.save_game()

func execute_hangar_override() -> bool:
	var couplings: Array = GameState.puzzle_flags.get("hangar_couplings", [false, false, false])
	if not couplings.all(func(value: Variant) -> bool: return bool(value)):
		puzzle_failed.emit("hangar_override", "Os três acoplamentos hidráulicos ainda não estão conectados")
		return false
	if not GameState.has_item("omega_master_card"):
		puzzle_failed.emit("hangar_override", "Cartão Mestre Ômega ausente")
		return false
	GameState.set_flag("hangar_override_complete")
	puzzle_solved.emit("hangar_override")
	GameState.save_game()
	return true

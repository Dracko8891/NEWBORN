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

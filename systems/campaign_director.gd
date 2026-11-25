extends Node

signal objective_updated(chapter: int, objective_index: int, objective_text: String)
signal chapter_started(chapter: int, title: String)
signal chapter_completed(chapter: int)
signal campaign_message(message: String)

const Campaign = preload("res://systems/campaign_data.gd")
var current_objective: int = 0
var chapter_transition_pending: bool = false
var objective_done: Dictionary = {}
var chapter_scene_paths: Array[String] = [
	"res://chapters/chapter_01.tscn",
	"res://chapters/chapter_02.tscn",
	"res://chapters/chapter_03.tscn",
	"res://chapters/chapter_04.tscn",
	"res://chapters/chapter_05.tscn",
	"res://chapters/chapter_06.tscn",
	"res://chapters/chapter_07.tscn"
]

func _ready() -> void:
	chapter_completed.connect(_on_chapter_completed)

func begin_chapter(chapter: int) -> void:
	GameState.set_chapter(chapter)
	var saved_chapter := int(GameState.puzzle_flags.get("campaign_saved_chapter", 0))
	if saved_chapter == chapter:
		restore_campaign_state()
	else:
		current_objective = 0
		save_campaign_state()
	var data := Campaign.get_chapter(chapter)
	if data.is_empty():
		return
	chapter_started.emit(chapter, str(data.title))
	_emit_current_objective()

func complete_objective(objective_id: String) -> bool:
	if not _objective_requirements_met(objective_id):
		campaign_message.emit("Objetivo bloqueado: conclua primeiro a tarefa ou puzzle correspondente.")
		return false
	var data := Campaign.get_chapter(GameState.chapter)
	if data.is_empty():
		return false
	var objectives: Array = data.objectives
	if current_objective >= objectives.size():
		return false
	var expected_id := "c%d_o%d" % [GameState.chapter, current_objective + 1]
	if objective_id != expected_id or objective_done.get(objective_id, false):
		return false
	objective_done[objective_id] = true
	current_objective += 1
	save_campaign_state()
	if current_objective >= objectives.size():
		chapter_completed.emit(GameState.chapter)
		campaign_message.emit("Capítulo concluído: " + str(data.title))
	else:
		_emit_current_objective()
	return true

func _emit_current_objective() -> void:
	var data := Campaign.get_chapter(GameState.chapter)
	var objectives: Array = data.get("objectives", [])
	if current_objective < objectives.size():
		objective_updated.emit(GameState.chapter, current_objective, str(objectives[current_objective]))

func advance_chapter() -> bool:
	if GameState.chapter >= 7:
		campaign_message.emit("Campanha concluída. Sinal perdido.")
		return false
	var next_chapter := GameState.chapter + 1
	var scene_path := chapter_scene_paths[next_chapter - 1]
	if not ResourceLoader.exists(scene_path):
		campaign_message.emit("Próximo setor ainda não está disponível: " + scene_path)
		return false
	GameState.set_chapter(next_chapter)
	current_objective = 0
	save_campaign_state()
	get_tree().change_scene_to_file(scene_path)
	return true

func save_campaign_state() -> void:
	GameState.puzzle_flags["campaign_saved_chapter"] = GameState.chapter
	GameState.puzzle_flags["campaign_objective"] = current_objective
	GameState.puzzle_flags["campaign_objective_done"] = objective_done
	GameState.save_game()

func restore_campaign_state() -> void:
	var saved_done: Variant = GameState.puzzle_flags.get("campaign_objective_done", {})
	objective_done = saved_done if typeof(saved_done) == TYPE_DICTIONARY else {}
	var data := Campaign.get_chapter(GameState.chapter)
	var objective_count := int(data.get("objectives", []).size())
	current_objective = clampi(int(GameState.puzzle_flags.get("campaign_objective", 0)), 0, objective_count)

func _on_chapter_completed(chapter: int) -> void:
	if chapter_transition_pending:
		return
	chapter_transition_pending = true
	if chapter >= 7:
		campaign_message.emit("SINAL PERDIDO — A criatura alcançou a superfície.")
		return
	await get_tree().create_timer(2.0).timeout
	chapter_transition_pending = false
	advance_chapter()


func _objective_requirements_met(objective_id: String) -> bool:
	var required_flags := {
		"c1_o1": [],
		"c1_o2": ["medical_door_unlocked"],
		"c1_o3": ["medical_relays_restored"],
		"c1_o4": ["medical_relays_restored", "medical_door_unlocked"],
		"c2_o1": [],
		"c2_o2": ["dna_matrix_calibrated"],
		"c2_o5": ["east_field_disabled"],
		"c3_o1": ["quarters_code_unlocked"],
		"c3_o2": [],
		"c3_o3": ["therapy_melody_solved"],
		"c3_o4": ["alpha_chip_recovered", "tricorder_level_2"],
		"c4_o1": [],
		"c4_o2": ["synthesis_compound_created"],
		"c4_o3": ["ammonia_fog_drained"],
		"c4_o4": ["genesis_valves_solved"],
		"c4_o5": ["beta_chip_recovered"],
		"c5_o2": ["reactor_shutdown_complete"],
		"c5_o3": ["robot_arms_operated"],
		"c5_o4": ["electric_arc_used"],
		"c5_o5": ["gamma_chip_recovered"],
		"c6_o1": ["tricorder_level_2"],
		"c6_o2": ["omega_biochips_solved"],
		"c6_o3": ["omega_download_complete"],
		"c6_o4": ["omega_siege_survived"],
		"c6_o5": ["omega_master_card_recovered"],
		"c7_o2": ["hangar_couplings_complete"],
		"c7_o3": ["omega_card_inserted"],
		"c7_o4": ["hangar_override_complete"],
		"c7_o5": ["surface_escape_complete"]
	}
	for flag in required_flags.get(objective_id, []):
		if not bool(GameState.get_flag(flag, false)):
			return false
	var required_items := {
		"c1_o1": {"kit_estanca":1},
		"c1_o2": {"supervisor_badge":1, "pin_note_0719":1},
		"c2_o1": {"calibration_chip_east":1, "calibration_chip_west":1},
		"c3_o2": {"uv_flare":1},
		"c4_o1": {"gas_mask":1},
		
		"c5_o4": {"electric_arc":1},
		"c7_o3": {"omega_master_card":1}
	}
	for item_id in required_items.get(objective_id, {}):
		var amount := int(required_items[objective_id][item_id])
		if not _has_quest_item(str(item_id), amount):
			return false
	return true

func _has_quest_item(item_id: String, amount: int) -> bool:
	if GameState.has_item(item_id, amount):
		return true
	var prefix := "chapter_%d:c%d_%s_" % [GameState.chapter, GameState.chapter, item_id]
	var collected := 0
	for pickup_key in GameState.collected_flags:
		if str(pickup_key).begins_with(prefix):
			collected += 1
	return collected >= amount

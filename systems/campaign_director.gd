extends Node

signal objective_updated(chapter: int, objective_index: int, objective_text: String)
signal chapter_started(chapter: int, title: String)
signal chapter_completed(chapter: int)
signal campaign_message(message: String)

const Campaign = preload("res://systems/campaign_data.gd")
var current_objective: int = 0
var chapter_transition_pending: bool = false

func _ready() -> void:
	chapter_completed.connect(_on_chapter_completed)
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

func begin_chapter(chapter: int) -> void:
	GameState.set_chapter(chapter)
	current_objective = 0
	var data := Campaign.get_chapter(chapter)
	if data.is_empty():
		return
	chapter_started.emit(chapter, str(data.title))
	_emit_current_objective()

func complete_objective(objective_id: String) -> bool:
	var data := Campaign.get_chapter(GameState.chapter)
	if data.is_empty():
		return false
	var objectives: Array = data.objectives
	if current_objective >= objectives.size():
		return false
	var expected_id := "c%d_o%d" % [GameState.chapter, current_objective + 1]
	if objective_id != expected_id:
		return false
	if objective_done.get(objective_id, false):
		return false
	objective_done[objective_id] = true
	current_objective += 1
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
	get_tree().change_scene_to_file(scene_path)
	return true

func save_campaign_state() -> void:
	GameState.puzzle_flags["campaign_objective"] = current_objective
	GameState.puzzle_flags["campaign_objective_done"] = objective_done
	GameState.save_game()

func restore_campaign_state() -> void:
	current_objective = int(GameState.puzzle_flags.get("campaign_objective", 0))
	objective_done = GameState.puzzle_flags.get("campaign_objective_done", {})
	_emit_current_objective()

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

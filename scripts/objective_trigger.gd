extends Area3D
class_name NewbornObjectiveTrigger

@export var objective_id: String = ""
@export var prompt: String = "Interagir"
@export var one_shot: bool = true
var activated: bool = false

func interact(_player: Node) -> void:
	if activated and one_shot:
		return
	if objective_id.is_empty():
		return
	if CampaignDirector.complete_objective(objective_id):
		activated = true
		GameState.notification_requested.emit(prompt)

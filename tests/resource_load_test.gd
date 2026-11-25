extends SceneTree

const CRITICAL_RESOURCES := [
	"res://scenes/main.tscn",
	"res://scenes/player.tscn",
	"res://ai/newborn_hunter.tscn",
	"res://chapters/epilogue.tscn",
	"res://chapters/chapter_01.tscn",
	"res://chapters/chapter_02.tscn",
	"res://chapters/chapter_03.tscn",
	"res://chapters/chapter_04.tscn",
	"res://chapters/chapter_05.tscn",
	"res://chapters/chapter_06.tscn",
	"res://chapters/chapter_07.tscn"
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for resource_path in CRITICAL_RESOURCES:
		var resource := ResourceLoader.load(resource_path)
		assert(resource != null, "Critical resource failed to load: " + resource_path)
		assert(resource is PackedScene, "Critical scene is not a PackedScene: " + resource_path)
	print("NEWBORN critical scene/resource load test: PASS")
	quit(0)

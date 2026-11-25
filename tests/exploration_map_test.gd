extends Node

const CampaignLevelScript = preload("res://chapters/campaign_level.gd")

func _ready() -> void:
	for chapter in range(1, 8):
		var level := Node3D.new()
		level.set_script(CampaignLevelScript)
		level.set("chapter_number", chapter)
		add_child(level)
		level.call("_build_exploration_routes")
		assert(level.get_node_or_null("Annex_%d_Workbench" % chapter) != null, "Missing chapter annex: %d" % chapter)
		assert(level.get_node_or_null("AnnexSign_%d" % chapter) != null, "Missing annex sign: %d" % chapter)
		for marker_index in range(7):
			assert(level.get_node_or_null("Wayfinding_FloorMark_%02d" % marker_index) != null)
			assert(level.get_node_or_null("Wayfinding_Sector_%02d" % marker_index) != null)
		level.free()

	print("NEWBORN seven chapter annex / wayfinding map tests: PASS")
	get_tree().quit(0)

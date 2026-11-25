extends SceneTree

const CampaignLevelScript = preload("res://chapters/campaign_level.gd")
const MapData = preload("res://systems/world_map_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for chapter in range(1, 8):
		var level := Node3D.new()
		root.add_child(level)
		level.set_script(CampaignLevelScript)
		level.set("chapter_number", chapter)
		level.call("_build_room_location_markers")
		var markers := 0
		for child in level.get_children():
			if child is not Area3D or not child.name.begins_with("RoomMarker_"):
				continue
			markers += 1
			var room_id := str(child.get("room_id"))
			var room_name := str(child.get("room_name"))
			var room := MapData.get_room(room_id)
			assert(not room.is_empty(), "Chapter %d marker references unknown room id: %s" % [chapter, room_id])
			assert(str(room.get("name", "")) == room_name, "Chapter %d marker name mismatch for %s: %s" % [chapter, room_id, room_name])
		assert(markers >= 4, "Chapter %d should have at least four physical room marker zones" % chapter)
		level.free()

	print("NEWBORN physical room marker / map data consistency tests: PASS")
	quit(0)

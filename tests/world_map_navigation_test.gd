extends SceneTree

const Navigation = preload("res://systems/world_map_navigation.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var topology_errors := Navigation.validate_topology()
	assert(topology_errors.is_empty(), "Map topology errors: " + str(topology_errors))

	var chapter_one := Navigation.rooms_for_chapter(1)
	assert(chapter_one.size() == 4, "Chapter 1 should expose its four authored map rooms")

	var security_neighbors := Navigation.adjacent_rooms("c1_security")
	assert(security_neighbors.size() == 1)
	assert(str(security_neighbors[0].room.id) == "c1_triage")

	var relay_edge := Navigation.connection_between("c1_relay", "c1_hatch")
	assert(not relay_edge.is_empty())
	assert(str(relay_edge.get("state", "")) == "locked_until_relays_and_pin")

	var triage_items := Navigation.items_in_room("c1_triage")
	assert(triage_items.size() == 2, "Triage should list its two authored key items")

	var campaign_route := Navigation.find_route("c1_security", "surface")
	assert(campaign_route.size() > 7, "A connected route should span the campaign")
	assert(campaign_route.front() == "c1_security")
	assert(campaign_route.back() == "surface")

	var same_room_route := Navigation.find_route("c1_triage", "c1_triage")
	assert(same_room_route == ["c1_triage"])
	assert(Navigation.find_route("unknown_room", "surface").is_empty())

	print("NEWBORN world map navigation / topology tests: PASS")
	quit(0)

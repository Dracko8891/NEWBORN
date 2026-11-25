extends RefCounted
class_name NewbornWorldNavigation

const MapData = preload("res://systems/world_map_data.gd")

static func rooms_for_chapter(chapter: int) -> Array:
	var result: Array = []
	for room in MapData.get_rooms():
		if int(room.get("chapter", 0)) == chapter:
			result.append(room)
	return result

static func items_in_room(room_id: String) -> Array:
	var result: Array = []
	for item in MapData.get_item_locations():
		if str(item.get("room", "")) == room_id:
			result.append(item)
	return result

static func connection_between(from_room: String, to_room: String) -> Dictionary:
	for edge in MapData.get_connections():
		if str(edge.get("from", "")) == from_room and str(edge.get("to", "")) == to_room:
			return edge
	return {}

static func adjacent_rooms(room_id: String) -> Array:
	var result: Array = []
	for edge in MapData.get_connections():
		if str(edge.get("from", "")) != room_id:
			continue
		var destination := MapData.get_room(str(edge.get("to", "")))
		if not destination.is_empty():
			result.append({"room": destination, "connection": edge})
	return result

# Finds the shortest authored route. Locked edges are included; gameplay must
# still evaluate each edge's state before allowing traversal.
static func find_route(from_room: String, to_room: String) -> Array[String]:
	var route: Array[String] = []
	if MapData.get_room(from_room).is_empty() or MapData.get_room(to_room).is_empty():
		return route
	if from_room == to_room:
		route.append(from_room)
		return route
	var queue: Array[String] = [from_room]
	var previous: Dictionary = {from_room: ""}
	var found := false
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for edge in MapData.get_connections():
			if str(edge.get("from", "")) != current:
				continue
			var next_room := str(edge.get("to", ""))
			if previous.has(next_room):
				continue
			previous[next_room] = current
			if next_room == to_room:
				found = true
				break
			queue.append(next_room)
		if found:
			break
	if not found:
		return route
	var cursor := to_room
	while not cursor.is_empty():
		route.push_front(cursor)
		cursor = str(previous.get(cursor, ""))
	return route

static func validate_topology() -> Array[String]:
	var errors: Array[String] = []
	var known_rooms: Dictionary = {}
	for room in MapData.get_rooms():
		var room_id := str(room.get("id", ""))
		if room_id.is_empty():
			errors.append("Room without id")
		elif known_rooms.has(room_id):
			errors.append("Duplicate room id: " + room_id)
		else:
			known_rooms[room_id] = true
		var chapter := int(room.get("chapter", 0))
		if chapter < 1 or chapter > 7:
			errors.append("Invalid chapter for room: " + room_id)
	var known_edges: Dictionary = {}
	for edge in MapData.get_connections():
		var origin := str(edge.get("from", ""))
		var destination := str(edge.get("to", ""))
		var edge_id := origin + "->" + destination
		if not known_rooms.has(origin):
			errors.append("Unknown connection origin: " + origin)
		if not known_rooms.has(destination):
			errors.append("Unknown connection destination: " + destination)
		if known_edges.has(edge_id):
			errors.append("Duplicate connection: " + edge_id)
		known_edges[edge_id] = true
	for item in MapData.get_item_locations():
		var room_id := str(item.get("room", ""))
		if not known_rooms.has(room_id):
			errors.append("Item references unknown room: " + str(item.get("item", "")))
	return errors

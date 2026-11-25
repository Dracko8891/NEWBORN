extends RefCounted
class_name NavMeshDirector
## Creates and asynchronously bakes a chapter navigation region from real static colliders.

static func garantir_navegacao_capitulo(level: Node3D) -> void:
	if level == null or not is_instance_valid(level):
		return
	var region := level.get_node_or_null("ChapterNavigationRegion") as NavigationRegion3D
	if region == null:
		region = NavigationRegion3D.new()
		region.name = "ChapterNavigationRegion"
		level.add_child(region)
	if region.navigation_mesh == null:
		var nav_mesh := NavigationMesh.new()
		nav_mesh.agent_radius = 0.35
		nav_mesh.agent_height = 1.7
		nav_mesh.agent_max_climb = 0.25
		nav_mesh.cell_size = 0.25
		nav_mesh.cell_height = 0.2
		nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
		nav_mesh.geometry_source_group_name = &"newborn_navmesh_source"
		nav_mesh.filter_baking_aabb = AABB(Vector3(-9.5, -0.5, -35.5), Vector3(19.0, 5.0, 71.0))
		region.navigation_mesh = nav_mesh
	level.add_to_group("newborn_navmesh_source")
	if region.navigation_mesh == null:
		push_warning("Chapter %d has no NavigationMesh resource" % int(level.get("chapter_number")))
		return
	region.bake_navigation_mesh(true)
	while region.is_baking():
		await level.get_tree().process_frame
	await level.get_tree().physics_frame

extends SceneTree

const NavMeshDirector = preload("res://systems/navmesh_director.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level := Node3D.new()
	level.name = "NavMeshBakeTest"
	root.add_child(level)
	level.add_to_group("newborn_navmesh_source")

	var floor_body := StaticBody3D.new()
	floor_body.name = "BakeFloor"
	floor_body.position = Vector3(0, -0.25, 0)
	level.add_child(floor_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(16, 0.5, 20)
	collision.shape = shape
	floor_body.add_child(collision)

	await physics_frame
	await NavMeshDirector.garantir_navegacao_capitulo(level)
	var region := level.get_node_or_null("ChapterNavigationRegion") as NavigationRegion3D
	assert(region != null, "Chapter navigation region should be created")
	assert(region.navigation_mesh != null, "Chapter NavigationMesh resource should exist")
	assert(region.navigation_mesh.get_polygon_count() > 0, "Background bake should produce walkable polygons")
	print("NEWBORN threaded chapter NavigationMesh bake test: PASS")
	quit(0)

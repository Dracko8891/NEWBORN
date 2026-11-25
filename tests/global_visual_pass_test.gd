extends SceneTree
## Regression test for the global visual pass across all campaign chapters.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for chapter in range(1, 8):
		var packed := load("res://chapters/chapter_%02d.tscn" % chapter) as PackedScene
		assert(packed != null, "Chapter scene must exist: %d" % chapter)
		var level := packed.instantiate()
		root.add_child(level)
		await process_frame
		await process_frame
		var floor_body := level.get_node_or_null("Setor_Piso") as StaticBody3D
		assert(floor_body != null, "Chapter floor must exist: %d" % chapter)
		var floor_mesh := floor_body.get_child(0) as MeshInstance3D
		var floor_box := floor_mesh.mesh as BoxMesh
		assert(is_equal_approx(floor_box.size.x, 3.2), "Main corridor must be 3.2 m wide")
		var roof := level.get_node_or_null("Setor_Teto") as StaticBody3D
		assert(roof != null, "Chapter ceiling must exist")
		var roof_mesh := roof.get_child(0) as MeshInstance3D
		assert(is_equal_approx((roof_mesh.mesh as BoxMesh).size.x, 3.2), "Ceiling span must match corridor width")
		var player := level.get_node_or_null("Player")
		assert(player != null, "Player must spawn in each chapter")
		var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
		assert(camera != null and is_equal_approx(camera.fov, 64.0), "Default camera FOV must be 64 degrees")
		var pbr_script := load("res://systems/horror_visual_director.gd")
		var material := pbr_script.material_for(chapter, "wall") as StandardMaterial3D
		assert(material.normal_texture != null and material.roughness_texture != null, "PBR maps must exist in every chapter")
		assert(material.normal_texture is NoiseTexture2D and material.roughness_texture is NoiseTexture2D, "PBR maps must use seamless procedural NoiseTexture2D")
		assert(level.find_child("ContainmentCCTV", true, false) != null, "CRT CCTV feed must exist in every chapter")
		var hud := level.find_child("MinimalDiegeticHUD", true, false)
		assert(hud != null, "Minimal translucent HUD must exist in every chapter")
		level.queue_free()
		await process_frame
	print("NEWBORN global visual scale / PBR / HUD regression test: PASS")
	quit(0)

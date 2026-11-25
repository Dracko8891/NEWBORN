extends RefCounted
## Shared, renderer-safe horror material/environment library.
## No external textures, decals, projector maps, SSR, SSAO or volumetric effects.

static var _materials: Dictionary = {}
static var _textures: Dictionary = {}

static func material_for(chapter: int, surface: String) -> StandardMaterial3D:
	var key := "%d:%s" % [chapter, surface]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var colors := [
		Color(0.24,0.105,0.095), Color(0.10,0.17,0.23), Color(0.24,0.16,0.09),
		Color(0.10,0.19,0.11), Color(0.07,0.09,0.13), Color(0.09,0.085,0.075), Color(0.18,0.20,0.23)
	]
	var base: Color = colors[clampi(chapter - 1, 0, 6)]
	var mat := StandardMaterial3D.new()
	match surface:
		"floor":
			mat.albedo_color = base.darkened(0.62)
			mat.metallic = 0.38
			mat.roughness = 0.32
		"metal":
			mat.albedo_color = base.darkened(0.28)
			mat.metallic = 0.78
			mat.roughness = 0.48
		"glass":
			mat.albedo_color = Color(0.10, 0.13, 0.14, 0.36)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.metallic = 0.25
			mat.roughness = 0.22
		_:
			mat.albedo_color = base
			mat.metallic = 0.28
			mat.roughness = 0.74
	mat.normal_enabled = true
	mat.normal_texture = _noise_texture(chapter, surface, true)
	mat.normal_scale = 0.42 if surface == "floor" else 0.68
	mat.roughness_texture = _noise_texture(chapter, surface, false)
	_materials[key] = mat
	return mat

static func _noise_texture(chapter: int, surface: String, as_normal: bool) -> Texture2D:
	var key := "%d:%s:%s" % [chapter, surface, str(as_normal)]
	if _textures.has(key):
		return _textures[key] as Texture2D
	var noise := FastNoiseLite.new()
	noise.seed = chapter * 7919 + (31 if surface == "metal" else (67 if surface == "floor" else 13))
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.045 if surface == "floor" else 0.075
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.seamless_blend_skirt = 0.1
	texture.noise = noise
	texture.as_normal_map = as_normal
	texture.bump_strength = 0.32
	texture.normalize = true
	_textures[key] = texture
	return texture

static func chapter_accent(chapter: int) -> Color:
	var colors := [
		Color(0.68,0.045,0.025), Color(0.10,0.34,0.68), Color(0.82,0.38,0.08),
		Color(0.22,0.56,0.12), Color(0.08,0.28,0.82), Color(0.55,0.40,0.16), Color(0.34,0.52,0.72)
	]
	return colors[clampi(chapter - 1, 0, 6)]

static func apply_environment(env: Environment, chapter: int) -> void:
	var fog_colors := [
		Color(0.23,0.045,0.035), Color(0.055,0.13,0.22), Color(0.28,0.15,0.055),
		Color(0.08,0.22,0.10), Color(0.025,0.055,0.12), Color(0.13,0.105,0.07), Color(0.12,0.19,0.28)
	]
	var densities := [0.014, 0.010, 0.018, 0.026, 0.009, 0.012, 0.020]
	env.ambient_light_energy = 0.055
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.85
	env.fog_enabled = true
	env.fog_light_color = fog_colors[clampi(chapter - 1, 0, 6)]
	env.fog_density = densities[clampi(chapter - 1, 0, 6)]
	# Compatibility renderer has no Forward+ glow pipeline; emissive materials are used instead.

static func add_grime_quad(parent: Node3D, label: String, position: Vector3, size: Vector2, color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = label
	var quad := QuadMesh.new()
	quad.size = size
	mesh_node.mesh = quad
	mesh_node.position = position
	mesh_node.rotation = rotation
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = false
	mesh_node.material_override = mat
	parent.add_child(mesh_node)
	return mesh_node

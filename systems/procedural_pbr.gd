extends RefCounted
## Tiny deterministic procedural PBR cache. Textures are generated once per theme/surface.

static var _cache: Dictionary = {}

static func material_for(theme: int, surface: String) -> StandardMaterial3D:
	var key := "%d_%s" % [theme, surface]
	if _cache.has(key):
		return _cache[key] as StandardMaterial3D
	var palettes := [
		Color(0.26,0.19,0.18), Color(0.13,0.22,0.29), Color(0.27,0.20,0.13),
		Color(0.12,0.24,0.16), Color(0.10,0.13,0.18), Color(0.10,0.11,0.14), Color(0.22,0.23,0.24)
	]
	var base: Color = palettes[clampi(theme - 1, 0, 6)]
	var floor_surface := surface == "floor"
	if floor_surface:
		base = base.darkened(0.58)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.metallic = 0.58 if surface == "metal" else (0.48 if floor_surface else 0.32)
	mat.roughness = 0.78 if floor_surface else 0.62
	mat.normal_enabled = true
	mat.normal_texture = _normal_texture(theme, surface)
	mat.normal_scale = 0.55 if floor_surface else 0.8
	mat.roughness_texture = _roughness_texture(theme, surface)
	_cache[key] = mat
	return mat

static func _height(x: int, y: int, theme: int, salt: float) -> float:
	var fx := float(x)
	var fy := float(y)
	return sin(fx * 0.29 + fy * 0.13 + salt) * 0.34 + cos(fy * 0.37 - fx * 0.11 + salt * 1.7) * 0.24 + sin((fx + fy) * 0.73 + float(theme)) * 0.12

static func _normal_texture(theme: int, surface: String) -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var salt := float(theme) * 0.91 + (2.0 if surface == "metal" else 0.0)
	for y in range(64):
		for x in range(64):
			var dx := (_height(x + 1, y, theme, salt) - _height(x - 1, y, theme, salt)) * 0.7
			var dy := (_height(x, y + 1, theme, salt) - _height(x, y - 1, theme, salt)) * 0.7
			var normal := Vector3(-dx, -dy, 1.0).normalized()
			image.set_pixel(x, y, Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 1.0))
	return ImageTexture.create_from_image(image)

static func _roughness_texture(theme: int, surface: String) -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var salt := float(theme) * 0.37 + (1.0 if surface == "floor" else 0.0)
	for y in range(64):
		for x in range(64):
			var n := clampf(0.68 + _height(x, y, theme, salt) * 0.24, 0.28, 0.96)
			if surface == "floor":
				n = clampf(n - 0.12, 0.18, 0.9)
			image.set_pixel(x, y, Color(n, n, n, 1.0))
	return ImageTexture.create_from_image(image)

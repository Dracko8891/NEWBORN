extends Node3D
## Lightweight cinematic layer: one screen shader, low-count CPU dust and a tiny first-person viewmodel.

const DUST_COUNT := 36
const BASE_FOV := 70.0

var _player: Node3D
var _camera: Camera3D
var _flashlight: SpotLight3D
var _dust: CPUParticles3D
var _overlay: ColorRect
var _shader_material: ShaderMaterial
var _viewmodel: Node3D
var _time := 0.0
var _fov_offset := 0.0
var _heartbeat := 0.0
var _enemy: Node3D
var _photosensitive := false

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return
	_camera = _player.get_node_or_null("Head/Camera3D") as Camera3D
	_flashlight = _player.get_node_or_null("Head/Camera3D/Flashlight") as SpotLight3D
	if _camera == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	_photosensitive = bool(game_state.get("photosensitive_mode")) if game_state != null else false
	_create_viewmodel()
	_create_screen_overlay()
	_create_dust()
	_enemy = get_tree().get_first_node_in_group("noise_listeners") as Node3D

func _create_screen_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CinematicOverlay"
	layer.layer = 40
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.name = "FilmAndVignette"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shader_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float grain_strength = 0.018;
uniform float vignette_strength = 0.42;
uniform float pulse = 0.0;
uniform float chromatic = 0.0;
uniform float clock = 0.0;
uniform float threat = 0.0;
uniform float crt_scan = 0.0;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	float edge = smoothstep(0.22, 0.78, length(centered) * 1.38);
	vec2 direction = normalize(centered + vec2(0.0001));
	float shift = chromatic * edge * 0.0025;
	vec3 col;
	col.r = texture(screen_texture, uv + direction * shift).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - direction * shift).b;
	float noise = hash21(floor(uv * vec2(1280.0, 720.0) + clock * 37.0));
	float grain = (noise - 0.5) * grain_strength;
	float scan = sin(uv.y * 920.0 + clock * 2.0) * crt_scan * 0.025;
	float interference = step(0.997, hash21(vec2(floor(clock * 3.0), floor(uv.y * 12.0)))) * threat * 0.035;
	float vignette = 1.0 - edge * (vignette_strength + pulse * 0.12);
	col = col * vignette + grain + scan + interference;
	COLOR = vec4(col, 1.0);
}
"""
	_shader_material.shader = shader
	_overlay.material = _shader_material
	layer.add_child(_overlay)

func _create_viewmodel() -> void:
	_viewmodel = Node3D.new()
	_viewmodel.name = "ArthurFirstPersonArms"
	_viewmodel.position = Vector3.ZERO
	_camera.add_child(_viewmodel)
	var skin := _material(Color(0.31, 0.25, 0.22), 0.88)
	var sleeve := _material(Color(0.075, 0.085, 0.09), 0.94)
	var metal := _material(Color(0.12, 0.15, 0.17), 0.34, 0.72)
	_add_capsule(_viewmodel, "RightSleeve", Vector3(0.36, -0.42, -0.54), Vector3(0.18, 0.42, 0.18), sleeve)
	_add_sphere(_viewmodel, "RightHand", Vector3(0.30, -0.25, -0.78), Vector3(0.13, 0.12, 0.18), skin)
	_add_capsule(_viewmodel, "LeftSleeve", Vector3(-0.32, -0.53, -0.42), Vector3(0.16, 0.36, 0.16), sleeve)
	_add_sphere(_viewmodel, "LeftHand", Vector3(-0.18, -0.36, -0.77), Vector3(0.12, 0.10, 0.16), skin)
	_add_box(_viewmodel, "KineticFlashlightBody", Vector3(0.08, -0.23, -0.92), Vector3(0.12, 0.12, 0.48), metal)
	_add_box(_viewmodel, "FlashlightGrip", Vector3(0.08, -0.29, -0.82), Vector3(0.13, 0.18, 0.14), sleeve)

func _create_dust() -> void:
	_dust = CPUParticles3D.new()
	_dust.name = "FloatingSpores"
	_dust.amount = DUST_COUNT
	_dust.lifetime = 8.0
	_dust.explosiveness = 0.0
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust.emission_box_extents = Vector3(8.0, 2.5, 8.0)
	_dust.direction = Vector3(0.1, 1.0, 0.0)
	_dust.spread = 180.0
	_dust.initial_velocity_min = 0.025
	_dust.initial_velocity_max = 0.12
	_dust.gravity = Vector3(0.0, 0.015, 0.0)
	_dust.scale_amount_min = 0.012
	_dust.scale_amount_max = 0.035
	_dust.emitting = true
	var particle_material := StandardMaterial3D.new()
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_material.albedo_color = Color(0.66, 0.72, 0.69, 0.24)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.035)
	quad.material = particle_material
	_dust.draw_pass_1 = quad
	add_child(_dust)

func _process(delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_camera):
		return
	_time += delta
	if is_instance_valid(_dust) and _dust.is_inside_tree() and _camera.is_inside_tree():
		_dust.global_position = _camera.global_position + -_camera.global_basis.z * 3.0
		_dust.emitting = _flashlight != null and _flashlight.visible
	var enemy_distance := 100.0
	var hunting := false
	if is_instance_valid(_enemy) and _enemy.is_inside_tree() and _player.is_inside_tree():
		enemy_distance = _player.global_position.distance_to(_enemy.global_position)
		var state_value: Variant = _enemy.get("state")
		hunting = state_value != null and int(state_value) in [2, 3, 5]
	var fear := clampf(1.0 - enemy_distance / 12.0, 0.0, 1.0)
	var target_fov := lerpf(BASE_FOV, 56.0, fear) if hunting else lerpf(BASE_FOV, 64.0, fear * 0.45)
	_fov_offset = move_toward(_fov_offset, target_fov - BASE_FOV, delta * (2.0 if hunting else 3.2))
	_camera.fov = BASE_FOV + _fov_offset
	var heartbeat_rate := 1.0 + fear * 1.8
	_heartbeat = (sin(_time * TAU * heartbeat_rate) * 0.5 + 0.5) * fear
	var camera_bob := sin(_time * 1.7) * 0.008
	if is_instance_valid(_viewmodel):
		_viewmodel.position.y = camera_bob
		_viewmodel.rotation.z = sin(_time * 1.1) * 0.012 + fear * sin(_time * 8.0) * 0.018
		_viewmodel.rotation.x = fear * sin(_time * 11.0) * 0.012
	if _shader_material != null:
		_shader_material.set_shader_parameter("clock", _time)
		_shader_material.set_shader_parameter("pulse", 0.0 if _photosensitive else _heartbeat)
		_shader_material.set_shader_parameter("chromatic", 0.0 if _photosensitive else fear * (1.0 if hunting else 0.35))
		_shader_material.set_shader_parameter("grain_strength", 0.009 if _photosensitive else 0.018)
		_shader_material.set_shader_parameter("vignette_strength", 0.28 if _photosensitive else 0.42)
		_shader_material.set_shader_parameter("threat", 0.0 if _photosensitive else fear)
		_shader_material.set_shader_parameter("crt_scan", 0.0 if _photosensitive else (1.0 if enemy_distance < 8.0 or hunting else 0.0))

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _add_capsule(parent: Node3D, label: String, position: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	node.mesh = mesh
	node.position = position
	node.scale = scale_value
	node.material_override = material
	parent.add_child(node)
	return node


func _add_sphere(parent: Node3D, label: String, position: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	node.mesh = mesh
	node.position = position
	node.scale = scale_value
	node.material_override = material
	parent.add_child(node)
	return node


func _add_box(parent: Node3D, label: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)
	return node

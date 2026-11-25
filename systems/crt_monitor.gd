extends MeshInstance3D
## Compatibility-safe CRT noise feed. No rapid strobing; photosensitive mode reduces motion.

var _material: ShaderMaterial
var _clock := 0.0
var _photosensitive := false

func _ready() -> void:
	_photosensitive = bool(GameState.photosensitive_mode)
	_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float clock = 0.0;
uniform float motion = 1.0;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
void fragment() {
	vec2 uv = UV;
	float static_noise = hash21(floor(uv * vec2(190.0, 120.0) + vec2(clock * 17.0 * motion, clock * 4.0)));
	float scan = 0.90 + 0.10 * sin(uv.y * 500.0);
	float silhouette = smoothstep(0.40, 0.37, abs(uv.x - 0.52)) * smoothstep(0.18, 0.28, uv.y) * smoothstep(0.92, 0.68, uv.y);
	vec3 base = vec3(0.012, 0.022, 0.026) + vec3(0.10, 0.13, 0.14) * static_noise * 0.20;
	base = mix(base, vec3(0.002, 0.003, 0.004), silhouette * 0.92);
	base *= scan;
	ALBEDO = base;
	EMISSION = base * 0.32 + vec3(0.10, 0.012, 0.008) * step(0.985, static_noise) * motion;
}
"""
	_material.shader = shader
	material_override = _material

func _process(delta: float) -> void:
	_clock += delta
	if _material != null:
		_material.set_shader_parameter("clock", _clock)
		_material.set_shader_parameter("motion", 0.12 if _photosensitive else 1.0)

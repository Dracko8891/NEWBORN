extends CharacterBody3D
class_name NewbornPlayer

@export var walk_speed: float = 3.0
@export var sprint_multiplier: float = 1.6
@export var crouch_speed: float = 1.45
@export var mouse_sensitivity: float = 0.0022
@export var gravity: float = 18.0
@export var flashlight_seconds: float = 240.0
@export var flashlight_recharge_seconds: float = 24.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

var stamina: float = 100.0
var flashlight_charge: float = 240.0
var flashlight_on: bool = true
var crouched: bool = false
var dynamo_busy: bool = false
var look_enabled: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	flashlight_charge = flashlight_seconds
	flashlight.visible = flashlight_on
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and look_enabled:
		_rotate_view(event.relative)
	elif event is InputEventScreenDrag and look_enabled:
		_rotate_view(event.relative)
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()
	elif event.is_action_pressed("crouch"):
		crouched = not crouched
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("dynamo"):
		pump_dynamo()

func _rotate_view(delta: Vector2) -> void:
	rotate_y(-delta.x * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x - delta.y * mouse_sensitivity, -1.35, 1.35)

func toggle_flashlight() -> void:
	if flashlight_charge > 0.0:
		flashlight_on = not flashlight_on
		flashlight.visible = flashlight_on

func pump_dynamo() -> void:
	if dynamo_busy or flashlight_charge >= flashlight_seconds:
		return
	dynamo_busy = true
	look_enabled = false
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	flashlight_charge = flashlight_seconds
	flashlight_on = true
	flashlight.visible = true
	dynamo_busy = false
	look_enabled = true
	get_tree().call_group("noise_listeners", "hear_noise", global_position, 0.9)

func interact() -> void:
	if interact_ray.is_colliding():
		var target: Object = interact_ray.get_collider()
		if target != null and target.has_method("interact"):
			target.interact(self)

func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()
	var sprinting := Input.is_action_pressed("sprint") and stamina > 0.0 and not crouched
	var speed := crouch_speed if crouched else walk_speed * (sprint_multiplier if sprinting else 1.0)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if sprinting and direction.length() > 0.1:
		stamina = maxf(0.0, stamina - 24.0 * delta)
		get_tree().call_group("noise_listeners", "hear_noise", global_position, 0.35)
	else:
		stamina = minf(100.0, stamina + 16.0 * delta)
	if flashlight_on and flashlight_charge > 0.0:
		flashlight_charge = maxf(0.0, flashlight_charge - delta)
		if flashlight_charge <= 0.0:
			flashlight.visible = false
			flashlight_on = false

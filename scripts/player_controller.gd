extends CharacterBody3D
class_name NewbornPlayer

@export var walk_speed := 3.0
@export var sprint_multiplier := 1.6
@export var crouch_speed := 1.45
@export var mouse_sensitivity := 0.0022
@export var gravity := 18.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

var stamina := 100.0
var flashlight_charge := 240.0
var flashlight_on := true
var crouched := false
var touch_look_delta := Vector2.ZERO

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    flashlight.visible = flashlight_on

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_view(event.relative)
    elif event is InputEventScreenDrag:
        # UI deve encaminhar apenas arrastos na zona direita da tela.
        _rotate_view(event.relative)
    elif event.is_action_pressed("flashlight"):
        toggle_flashlight()
    elif event.is_action_pressed("crouch"):
        crouched = not crouched

func _rotate_view(delta: Vector2) -> void:
    rotate_y(-delta.x * mouse_sensitivity)
    head.rotation.x = clampf(head.rotation.x - delta.y * mouse_sensitivity, -1.35, 1.35)

func toggle_flashlight() -> void:
    if flashlight_charge > 0.0:
        flashlight_on = not flashlight_on
        flashlight.visible = flashlight_on

func pump_dynamo() -> void:
    # Dínamo infinito: 3 s de bombeamento, produz ruído para a IA.
    await get_tree().create_timer(3.0).timeout
    flashlight_charge = 24.0
    flashlight_on = true
    flashlight.visible = true
    get_tree().call_group("noise_listeners", "hear_noise", global_position, 0.9)

func _physics_process(delta: float) -> void:
    var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_2d.x, 0, input_2d.y)).normalized()
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

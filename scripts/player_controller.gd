extends CharacterBody3D
class_name NewbornPlayer

@export var walk_speed := 3.0
@export var sprint_multiplier := 1.6
@export var crouch_speed := 1.45
@export var slide_speed := 5.0
@export var mouse_sensitivity := 0.0022
@export var gravity := 18.0
@export var flashlight_seconds := 240.0
@export var peek_distance := 0.45
@export var peek_collision_margin := 0.08

@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

const STAND_HEIGHT := 1.80
const CROUCH_HEIGHT := 0.95
const SLIDE_HEIGHT := 0.65
const BODY_RADIUS := 0.30

var stamina := 100.0
var flashlight_charge := 240.0
var flashlight_on := true
var crouched := false
var sliding := false
var dynamo_busy := false
var look_enabled := true
var hidden_in_cover := false
var in_safe_room := false
var crouched_before_hiding := false
var noise_level := 0.0
var noise_emit_timer := 0.0
var adrenaline_timer := 0.0
var dead := false
var _peek_input := 0.0
var _peek_offset := Vector3.ZERO
var _slide_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	flashlight_charge = clampf(GameState.flashlight_charge_saved, 0.0, flashlight_seconds)
	flashlight_on = flashlight_charge > 0.0
	flashlight.visible = flashlight_on
	_set_capsule_height(STAND_HEIGHT)
	camera.position = Vector3.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_inside_tree() and not dead:
			GameState.save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED and not dead:
		flashlight_charge = clampf(flashlight_charge, 0.0, flashlight_seconds)
		flashlight.visible = flashlight_on and flashlight_charge > 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and look_enabled:
		_rotate_view(event.relative)
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()
	elif event.is_action_pressed("crouch") and not hidden_in_cover:
		if Input.is_action_pressed("sprint"):
			begin_slide()
		else:
			set_crouched(not crouched)
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("dynamo"):
		pump_dynamo()
	elif event.is_action_pressed("use_medical"):
		use_medical_resource()
	elif event.is_action_pressed("use_battery"):
		use_battery_resource()
	elif event is InputEventKey and not event.pressed:
		if event.keycode == KEY_Q or event.keycode == KEY_E:
			set_peek(0.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			set_peek(-1.0)
		elif event.keycode == KEY_E:
			set_peek(1.0)
		elif event.keycode == KEY_ESCAPE:
			set_peek(0.0)

func _rotate_view(delta: Vector2) -> void:
	rotate_y(-delta.x * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x - delta.y * mouse_sensitivity, -1.35, 1.35)

func apply_touch_look(delta: Vector2) -> void:
	if look_enabled:
		_rotate_view(delta)

func is_hidden() -> bool:
	return hidden_in_cover

func is_dead() -> bool:
	return dead

func set_crouched(value: bool) -> void:
	if sliding or hidden_in_cover:
		return
	if value:
		_set_capsule_height(CROUCH_HEIGHT)
		crouched = true
	else:
		if _has_headroom(STAND_HEIGHT):
			_set_capsule_height(STAND_HEIGHT)
			crouched = false

func begin_slide() -> void:
	if sliding or hidden_in_cover or not is_on_floor() or stamina < 12.0:
		set_crouched(true)
		return
	sliding = true
	crouched = true
	_slide_timer = 0.8
	stamina -= 12.0
	_set_capsule_height(SLIDE_HEIGHT)

func _set_capsule_height(height: float) -> void:
	var capsule := body_shape.shape as CapsuleShape3D
	if capsule == null:
		capsule = CapsuleShape3D.new()
		body_shape.shape = capsule
	capsule.radius = BODY_RADIUS
	capsule.height = maxf(height, BODY_RADIUS * 2.0)
	body_shape.position.y = capsule.height * 0.5
	head.position.y = maxf(0.12, height - 0.18)

func _has_headroom(height: float) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(global_transform.basis, global_position + Vector3.UP * (height * 0.5))
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func enter_hide_spot() -> void:
	if hidden_in_cover:
		return
	crouched_before_hiding = crouched
	hidden_in_cover = true
	sliding = false
	crouched = true
	_set_capsule_height(CROUCH_HEIGHT)
	noise_level = 0.0
	velocity = Vector3.ZERO

func leave_hide_spot() -> void:
	if not hidden_in_cover:
		return
	hidden_in_cover = false
	crouched = crouched_before_hiding
	_set_capsule_height(CROUCH_HEIGHT if crouched else STAND_HEIGHT)
	noise_level = 0.0

func take_hit() -> void:
	if dead or adrenaline_timer > 0.0 or hidden_in_cover or in_safe_room:
		return
	if GameState.health_state == 0:
		GameState.set_health_state(1)
		adrenaline_timer = 3.0
		GameState.notification_requested.emit("Ferimento grave: encontre Kit de Estanca e Hipo-Spray")
		GameState.save_game()
	else:
		GameState.set_health_state(2)
		dead = true
		GameState.notification_requested.emit("SINAL PERDIDO")
		GameState.save_game()
		get_tree().paused = true

func set_peek(direction: float) -> void:
	_peek_input = clampf(direction, -1.0, 1.0)

func _update_peek() -> void:
	var desired := Vector3(_peek_input * peek_distance, 0.0, 0.0)
	if desired.is_zero_approx():
		_peek_offset = _peek_offset.move_toward(Vector3.ZERO, 0.08)
	else:
		var from := head.global_position
		var to := from + global_transform.basis * desired
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var allowed := desired.length()
		if not hit.is_empty():
			allowed = maxf(0.0, from.distance_to(hit.position) - peek_collision_margin)
		_peek_offset = Vector3(signf(desired.x) * minf(allowed, peek_distance), 0.0, 0.0)
	camera.position = _peek_offset

func toggle_flashlight() -> void:
	if flashlight_charge > 0.0:
		flashlight_on = not flashlight_on
		flashlight.visible = flashlight_on

func recharge_flashlight(amount: float = 90.0) -> bool:
	if amount <= 0.0 or flashlight_charge >= flashlight_seconds:
		return false
	flashlight_charge = minf(flashlight_seconds, flashlight_charge + amount)
	flashlight_on = true
	flashlight.visible = true
	return true

func pump_dynamo() -> void:
	if dynamo_busy or flashlight_charge >= flashlight_seconds or hidden_in_cover:
		return
	dynamo_busy = true
	look_enabled = false
	if not in_safe_room:
		get_tree().call_group("noise_listeners", "hear_noise", global_position, 0.9)
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	recharge_flashlight(flashlight_seconds)
	dynamo_busy = false
	look_enabled = true
	GameState.save_game()

func use_medical_resource() -> void:
	for item_id in ["kit_estanca", "hemostatic_kit", "bandage", "curativo", "kit_medico", "first_aid_kit", "medkit", "hypo_spray", "hipospray"]:
		if GameState.has_item(item_id):
			GameState.use_item(item_id, self)
			return
	GameState.notification_requested.emit("Você não possui itens médicos")

func use_battery_resource() -> void:
	for item_id in ["bateria", "battery", "energy_cell", "celula_energia"]:
		if GameState.has_item(item_id):
			GameState.use_item(item_id, self)
			return
	GameState.notification_requested.emit("Você não possui baterias")

func interact() -> void:
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var target: Object = interact_ray.get_collider()
		if target != null and target.has_method("interact"):
			target.interact(self)

func _physics_process(delta: float) -> void:
	if adrenaline_timer > 0.0:
		adrenaline_timer = maxf(0.0, adrenaline_timer - delta)
	noise_emit_timer = maxf(0.0, noise_emit_timer - delta)
	if dead:
		return
	_update_peek()
	if hidden_in_cover:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if sliding:
		_slide_timer -= delta
		if _slide_timer <= 0.0:
			sliding = false
			if crouched:
				_set_capsule_height(CROUCH_HEIGHT)
			elif _has_headroom(STAND_HEIGHT):
				_set_capsule_height(STAND_HEIGHT)
	if Input.is_action_just_pressed("slide"):
		begin_slide()
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var touch_layer := get_node_or_null("MobileControls/TouchSurface")
	if touch_layer != null and touch_layer.has_method("get_virtual_move"):
		var touch_move: Vector2 = touch_layer.get_virtual_move()
		if touch_move.length() > input_2d.length():
			input_2d = touch_move
	var direction := (global_transform.basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()
	var sprinting := Input.is_action_pressed("sprint") and stamina > 0.0 and not crouched and not sliding
	var speed := walk_speed
	if sliding:
		speed = slide_speed
	elif crouched:
		speed = crouch_speed
	elif sprinting:
		speed *= sprint_multiplier
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if sprinting and direction.length() > 0.1:
		stamina = maxf(0.0, stamina - 24.0 * delta)
		noise_level = 0.65
		if noise_emit_timer <= 0.0 and not in_safe_room:
			get_tree().call_group("noise_listeners", "hear_noise", global_position, noise_level)
			noise_emit_timer = 0.65
	else:
		stamina = minf(100.0, stamina + 16.0 * delta)
		noise_level = 0.08 if direction.length() > 0.1 and not crouched else 0.015
	if flashlight_on and flashlight_charge > 0.0:
		flashlight_charge = maxf(0.0, flashlight_charge - delta)
		if flashlight_charge <= 0.0:
			flashlight.visible = false
			flashlight_on = false
	GameState.flashlight_charge_saved = flashlight_charge

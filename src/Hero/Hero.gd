extends KinematicBody


signal jumped(completed)

export var run_acceleration := 8.0
export var run_max_speed := 4.0
export var sprint_acceleration := 4.0
export var sprint_max_speed := 12.0
export var brake := 12.0

export var jump_strength := 4.0
export var gravity := 6.0

export var look_sensitivity := 1.0

var velocity := Vector3()
var jump_buffering_pressed_time := 0
var coyote_time := 0

var selected_weapon : Spatial


func try_jump():
	emit_signal("jumped", false)
	if is_on_floor() || coyote_time > Time.get_ticks_msec() - 250:
		coyote_time = 0
		jump()

	else:
		jump_buffering_pressed_time = Time.get_ticks_msec()


func jump():
	emit_signal("jumped", true)
	if velocity.y < jump_strength:
		velocity.y = jump_strength


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	selected_weapon = $"%Weapons".get_child(0)
	selected_weapon.equip(self)


func _physics_process(delta):
	_process_movement_horizontal(delta)
	velocity.y -= gravity * delta
	if is_on_floor():
		coyote_time = Time.get_ticks_msec()
		if jump_buffering_pressed_time > Time.get_ticks_msec() - 400:
			jump_buffering_pressed_time = 0
			jump()

	velocity = move_and_slide(velocity, Vector3.UP)


func _process_movement_horizontal(delta):
	var input_vec := Input.get_vector(
		"strafe_left",
		"strafe_right",
		"move_fwd",
		"move_back"
	)
	var input_vec_transformed := Vector2(input_vec.x, input_vec.y).rotated(-rotation.y)
	var velocity_xz := Vector2(velocity.x, velocity.z)

	if input_vec != Vector2.ZERO:
		var velocity_delta := run_acceleration

		# After some speed gained, speed gain slows down.
		if velocity_xz.length_squared() > run_max_speed:
			velocity_delta = sprint_acceleration

		# If not going toward movement direction, brake - braking is faster than acceleration.
		var straight = (velocity_xz.normalized().dot(input_vec_transformed) + 1.0) * 0.5
		velocity_delta = velocity_delta * straight + brake * ((1.0 - straight))

		# Apply acceleartion
		velocity_xz = velocity_xz.move_toward(
			input_vec_transformed * sprint_max_speed, 
			velocity_delta * delta
		)
		
	elif is_on_floor():
		velocity_xz = velocity_xz.move_toward(Vector2.ZERO, brake * delta)

	velocity.x = velocity_xz.x
	velocity.z = velocity_xz.y


func _input(event):
	if event is InputEventKey:
		if event.is_echo(): return
		if event.scancode == KEY_ALT:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if event.pressed else Input.MOUSE_MODE_CAPTURED
			return
	
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * look_sensitivity
		$"Head".rotation_degrees.x = clamp($"Head".rotation_degrees.x - event.relative.y * look_sensitivity, -90, 90)
		return  # Mouse Motion can't be an Action
		
	_action_input(event)
	

func _action_input(event):
	if event.is_action("jump") && event.is_pressed():
		try_jump()
		
	if selected_weapon != null && event.is_action("fire_main"):
		if event.is_pressed(): 
			selected_weapon.fire()

		else: 
			selected_weapon.stop_firing()

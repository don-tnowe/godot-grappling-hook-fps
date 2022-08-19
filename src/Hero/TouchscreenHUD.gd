extends CanvasLayer


signal tilt_move(direction)
signal drag_look(offset)

export var tilt_deadzone := PI * 0.25
export var tilt_sensitivity := 48.0 / PI
export var look_minimum_x := 640

var is_touch := true
var anchor_basis := Basis()


func _ready():
	if !OS.has_touchscreen_ui_hint():
		is_touch = false
		$"BL/Touch".visible = false

	yield(get_tree(), "idle_frame")
	anchor_current_tilt(-Input.get_gravity().normalized())


func _physics_process(_delta):
	if !is_touch: return
	var gravity_up = -Input.get_gravity().normalized()
	
	if Input.is_action_pressed("move_stop"):
		anchor_current_tilt(gravity_up)

	var gravity_vec = anchor_basis.xform(gravity_up)
	var input_vec = Vector2(-gravity_vec.x * tilt_sensitivity, gravity_vec.y * tilt_sensitivity).limit_length(1)
	if input_vec.length_squared() > tilt_deadzone * tilt_deadzone:
		emit_signal("tilt_move", input_vec)
		$"%MoveDir".self_modulate = Color(1, 1, 1, 0.75)
	
	else:
		emit_signal("tilt_move", Vector2.ZERO)
		$"%MoveDir".self_modulate = Color(0, 0, 0, 0.75)
	
	$"%MoveDir".position = (input_vec + Vector2.ONE) * 128


func anchor_current_tilt(gravity_up):
	anchor_basis = Basis(
		gravity_up.cross(Vector3.UP).normalized(),
		gravity_up.angle_to(Vector3.UP) - PI * 0.5
	)


func _input(event):
	if event is InputEventScreenDrag && event.position.x > look_minimum_x:
		emit_signal("drag_look", event.relative)

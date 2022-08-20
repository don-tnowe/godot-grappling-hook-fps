extends Spatial


export var is_mobile := true


func _ready():
	if OS.has_touchscreen_ui_hint() != is_mobile:
		queue_free()

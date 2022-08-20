extends StaticBody


var velocity := Vector3() setget _set_velocity, _get_velocity


func _set_velocity(v):
	get_parent().velocity = v


func _get_velocity():
	return get_parent().velocity

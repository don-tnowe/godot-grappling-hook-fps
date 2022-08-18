extends Spatial


export var reel_in_acceleration := 24.0

var equipped := false
var firing := false
var hero_node : KinematicBody

var attached := false
var attached_tip := Vector3()
var attached_pivot := Vector3()
var attached_pivot_distance := 0.0


func equip(hero):
	hero_node = hero
	_set_equipped(true)
	hero.connect("jumped", self, "_on_Hero_jumped")


func unequip():
	_set_equipped(false)
	hero_node.disconnect("jumped", self, "_on_Hero_jumped")


func _set_equipped(v):
	visible = v
	equipped = v
	$"Crosshair".visible = v


func fire():
	firing = true
	if !attached:
		try_attach()


func stop_firing():
	firing = false
		

func try_attach():
	if $"RayCast".is_colliding():
		# If not in the "grapplable" layer, the object is - well - not grappleable!
		if !$"RayCast".get_collider().get_collision_layer_bit(5):
			return

		attach_to_point($"RayCast".get_collision_point())


func attach_to_point(point):
	attached_tip = point 
	attached_pivot = attached_tip
	attached_pivot_distance = hero_node.transform.origin.distance_to(attached_pivot)
	attached = true
	$"%Chain".visible = true


func unattach():
	attached = false
	$"%Chain".visible = false


func _physics_process(delta):
	if !equipped: return
		
	$"Crosshair/Crosshair".modulate = _get_crosshair_color()
	
	if !attached: return

	var abs_position = hero_node.transform.origin
	var rel_position = abs_position - attached_pivot

	if rel_position.length_squared() > attached_pivot_distance * attached_pivot_distance:
		var dir_from_hook = rel_position.normalized()
		hero_node.velocity = hero_node.velocity.slide(dir_from_hook)
		# Restrict hero position within attached_pivot_distance radius
		hero_node.move_and_collide(-rel_position + dir_from_hook * attached_pivot_distance)
		
	if firing:
		attached_pivot_distance = rel_position.length()
		hero_node.velocity -= reel_in_acceleration * delta * rel_position.normalized()
	
	$"%Chain".scale.z = abs_position.distance_to(attached_pivot)
	$"%Chain".look_at(attached_pivot, Vector3.UP)


func _get_crosshair_color():
	if $"RayCast".is_colliding():
		if !$"RayCast".get_collider().get_collision_layer_bit(5):
			return Color.red
		
		else: 
			return Color.cyan

	else:
		return Color.white


func _on_Hero_jumped(completed):
	if !attached: return
	if completed: return
	
	if attached_pivot.y > hero_node.translation.y:
		hero_node.jump()

	unattach()
	

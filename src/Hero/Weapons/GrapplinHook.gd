extends WeaponBase


export var reel_in_acceleration := 24.0

var attached := false
var attached_tip := Vector3()
var attached_pivot := Vector3()
var attached_pivot_distance := 0.0
var attached_object : Spatial
var bend_points := []


func equip(hero):
	.equip(hero)
	hero.connect("jumped", self, "_on_Hero_jumped")


func unequip():
	.unequip()
	detach()
	hero_node.disconnect("jumped", self, "_on_Hero_jumped")


func _set_equipped(v):
	visible = v
	equipped = v
	$"Crosshair".visible = v


func fire(refire = false):
	firing = true
	if !attached:
		try_attach()


func try_attach():
	if $"RayCast".is_colliding():
		# If not in the "grapplable" layer, the object is - well - not grappleable!
		if !$"RayCast".get_collider().get_collision_layer_bit(5):
			return
		
		if $"RayCast".get_collider().has_method("grapple_attach"):
			$"RayCast".get_collider().grapple_attach()

		attached_object = $"RayCast".get_collider()
			
		attach_to_point($"RayCast".get_collision_point() + $"RayCast".get_collision_normal() * 0.2)


func attach_to_point(point):
	attached_tip = point 
	attached_pivot = attached_tip
	attached_pivot_distance = hero_node.translation.distance_to(attached_pivot)
	attached = true
	$"%Chain".visible = true


func detach():
	attached = false
	$"%Chain".visible = false
	bend_points = []
	if is_instance_valid(attached_object) && attached_object.has_method("grapple_detach"):
		attached_object.grapple_detach()
	
	attached_object = null
	for x in $"%Chain/Segments".get_children():
		x.visible = false


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
		hero_node.velocity -= (reel_in_acceleration * rel_position.normalized() + Vector3(0, -hero_node.gravity, 0)) * delta
	
	_check_obstacles(rel_position, abs_position)
	_draw_rope(abs_position)


func _get_crosshair_color():
	if $"RayCast".is_colliding():
		if !$"RayCast".get_collider().get_collision_layer_bit(5):
			return Color.red
		
		else: 
			return Color.cyan

	else:
		return Color.white


func _check_obstacles(rel_position, hero_position):
	$"ToPivot".translation = Vector3.ZERO
	$"ToPivot".global_rotation = Vector3.ZERO
	$"ToPivot".cast_to = -rel_position * 0.98 - Vector3(0, 0.1, 0)
	$"ToPivot".force_raycast_update()

	# If the current pivot is unreachable, it bends.
	if $"ToPivot".is_colliding() && attached_pivot_distance > 0.75:
		var point1 = $"ToPivot".get_collision_point()
		var normal1 = $"ToPivot".get_collision_normal()

		# Cast from opposite direction to get both hit points.
		$"ToPivot".global_translation = attached_pivot
		$"ToPivot".cast_to = rel_position
		$"ToPivot".force_raycast_update()
		# Project point 2 onto plane with point 1's normal in point 1 space.
		var point1_to_edge = Plane(normal1, 0).project($"ToPivot".get_collision_point() - point1)
		var edge_point = point1 + point1_to_edge + (normal1 + $"ToPivot".get_collision_normal()) * 0.2

		_add_bend(edge_point)
	
	if bend_points.size() == 0: return
	
	var last_bend_point = bend_points[bend_points.size() - 1]
	$"ToBend".global_rotation = Vector3.ZERO
	$"ToBend".cast_to = (last_bend_point - hero_position)
	$"ToBend".force_raycast_update()
	
	# If the last pivot is reachable, the last bend tries to straighten.
	if !$"ToBend".is_colliding():
		var delta := Vector3.ZERO
		
		$"ToBendProjection".global_rotation = Vector3.ZERO
		while true:
			# Cast from current bend toward convergence point
			delta = ((last_bend_point + hero_position) * 0.5 - attached_pivot).normalized() * 0.02
			$"ToBendProjection".global_translation = attached_pivot
			$"ToBendProjection".cast_to = delta
			$"ToBendProjection".force_raycast_update()

			_pop_bend()
			# If an obstacle catches the rope, it stops straightening.
			if $"ToBendProjection".is_colliding():
				_add_bend($"ToBendProjection".get_collision_point())
				break
			# If rope partially straightened, keep doing that until close to convergence point.
			_add_bend($"ToBendProjection".global_translation + delta)
			if ((last_bend_point + hero_position) * 0.5).distance_squared_to(attached_pivot) < 0.05 * 0.05:
				# Done! Rope fully straightened.
				_pop_bend()
				break


func _pop_bend():
	var point = bend_points.pop_back()
	attached_pivot_distance += attached_pivot.distance_to(point)
	attached_pivot = point

	if bend_points.size() < $"%Chain/Segments".get_child_count():
		$"%Chain/Segments".get_child(bend_points.size()).visible = false


func _add_bend(point):
	bend_points.append(attached_pivot)
	_draw_rope_bent(attached_pivot, point, bend_points.size() - 1)
	attached_pivot_distance -= attached_pivot.distance_to(point)
	attached_pivot = point
	

func _draw_rope(hero_position):
	var segment = $"%Chain"
	segment.scale.z = hero_position.distance_to(attached_pivot)
	segment.look_at(attached_pivot, Vector3.UP)


func _draw_rope_bent(from, to, index):
	if bend_points.size() > $"%Chain/Segments".get_child_count(): return
	var segment = $"%Chain/Segments".get_child(index)
	segment.visible = true
	segment.scale.z = from.distance_to(to)
	segment.translation = from
	segment.look_at(to, Vector3.UP)


func _on_Hero_jumped(completed):
	if !attached: return
	if completed: return
	
	if attached_pivot.y > hero_node.translation.y - 1.5:
		hero_node.jump()

	detach()
	

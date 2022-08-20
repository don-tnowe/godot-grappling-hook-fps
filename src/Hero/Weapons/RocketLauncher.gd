extends WeaponBase


export var rocket_scene : PackedScene
export var instant_trigger_distance := 5.0


func fire(refire = false):
	firing = true
	if !can_refire(): return
	
	last_fired = Time.get_ticks_msec()
	_spawn_projectile(Vector3.FORWARD)


func _spawn_projectile(dir):
	var rocket = rocket_scene.instance()
	$"Global".add_child(rocket)

	$"RayCast".force_raycast_update()
	if $"RayCast".is_colliding():
		var point = $"RayCast".get_collision_point()
		rocket.launch($"%FiringOrigin".global_translation.direction_to(point))
		if global_translation.distance_squared_to(point) < instant_trigger_distance * instant_trigger_distance:
			rocket.translation = point
			rocket.impact_normal = $"RayCast".get_collision_normal()
			rocket.collide()
			return

	else:
		rocket.launch(global_transform.basis.xform(dir))

	rocket.velocity += hero_node.velocity * 0.66
	rocket.translation = $"%FiringOrigin".global_translation


func _physics_process(_delta):
	if firing && can_refire():
		fire(true)

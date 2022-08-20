extends WeaponBase


export var rocket_scene : PackedScene
export var instant_trigger_distance := 3.0


func fire():
	if !can_refire(): return
	.fire()
	_spawn_projectile()


func _spawn_projectile():
	var rocket = rocket_scene.instance()
	$"Global".add_child(rocket)

	$"RayCast".force_raycast_update()
	if $"RayCast".is_colliding():
		var point = $"RayCast".get_collision_point()
		rocket.launch($"%FiringOrigin".global_translation.direction_to(point))
		if global_translation.distance_squared_to(point) < instant_trigger_distance * instant_trigger_distance:
			rocket.translation = point
			rocket.collide()
			return

	else:
		rocket.launch(global_transform.basis.xform(Vector3.FORWARD))

	rocket.velocity += hero_node.velocity * 0.66
	rocket.translation = $"%FiringOrigin".global_translation


func _physics_process(_delta):
	if firing && can_refire():
		fire()

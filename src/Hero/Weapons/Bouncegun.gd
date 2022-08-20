extends WeaponBase


export var bullet_scene : PackedScene
export var recoil_impulse := 1.0


func fire(refire = false):
	firing = true
	if !can_refire(): return
	
	last_fired = Time.get_ticks_msec()
	hero_node.velocity += global_transform.basis.xform(Vector3(0, 0, recoil_impulse))
	_spawn_projectile(Vector3.FORWARD)


func _spawn_projectile(dir):
	$"RayCast".force_raycast_update()
	if $"RayCast".is_colliding():
		var point = $"RayCast".get_collision_point()
		dir = $"%FiringOrigin".global_translation.direction_to(point)
		
	else:
		dir = global_transform.basis.xform(Vector3.FORWARD)
		
	var bullet = bullet_scene.instance()
	$"Global".add_child(bullet)
	bullet.launch(dir)
	bullet.translation = $"%FiringOrigin".global_translation


func _physics_process(_delta):
	if firing && can_refire():
		fire(true)

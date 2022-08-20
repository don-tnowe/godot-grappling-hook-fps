extends WeaponBase


export var scatter_count := 24
export var scatter_spread_degrees := 45.0
export var scatter_noise_degrees := 15.0

export var bullet_scene : PackedScene
export var recoil_impulse := 4.0
export var bullet_knockback_multiplier := 0.75

var last_firing_start := 0


func fire(_refire = false):
	if !can_refire(): return
	
	last_fired = Time.get_ticks_msec()
	hero_node.velocity += global_transform.basis.xform(Vector3(0, 0, recoil_impulse))
	_fire_scatter()


func _fire_scatter():
	var hero_on_floor = hero_node.is_on_floor()
	for i in scatter_count:
		var offset = i / float(scatter_count) - 0.5
		var angle_offset = Vector2(
			offset * deg2rad(scatter_spread_degrees),
			deg2rad((randf() - 0.5) * scatter_noise_degrees * (0.5 - abs(offset)))
		)
		_spawn_projectile(Vector3.FORWARD\
			.rotated(Vector3.UP, angle_offset.x if hero_on_floor else angle_offset.y)\
			.rotated(Vector3.RIGHT, angle_offset.y if hero_on_floor else angle_offset.x)
		)


func _spawn_projectile(dir):
	$"RayCast".cast_to = dir * 4000
	$"RayCast".force_raycast_update()
	if $"RayCast".is_colliding():
		var point = $"RayCast".get_collision_point()
		dir = $"%FiringOrigin".global_translation.direction_to(point)
		
	else:
		dir = global_transform.basis.xform(dir)
		
	var bullet = bullet_scene.instance()
	$"Global".add_child(bullet)
	bullet.launch(dir)
	bullet.translation = $"%FiringOrigin".global_translation
	bullet.hit_knockback *= bullet_knockback_multiplier

extends WeaponBase


export var scatter_max_press_time := 0.25
export var firing_cooldown_fast := 0.1
export var firing_cooldown_scatter := 0.75

export var bullet_scene : PackedScene
export var recoil_impulse := 1.0

var last_firing_start := 0


func fire(refire = false):
	if !refire:
		last_firing_start = Time.get_ticks_msec()
	
	firing = true
	if !can_refire(): return
	
	last_fired = Time.get_ticks_msec()
	hero_node.velocity += global_transform.basis.xform(Vector3(0, 0, recoil_impulse))
	firing_cooldown = firing_cooldown_fast
	_spawn_projectile(Vector3.FORWARD)


func stop_firing():
	.stop_firing()
	if Time.get_ticks_msec() <= last_firing_start + scatter_max_press_time * 1000:
		firing_cooldown = firing_cooldown_scatter
		$"BouncyScatter".fire()


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


func _physics_process(_delta):
	if firing && can_refire():
		fire(true)

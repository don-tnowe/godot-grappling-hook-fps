extends KinematicBody


export var rocket_speed := 6.0
export var explosion_power := 20.0
export var explosion_radius := 6.0
export var explosion_power_normal := 10.0

var velocity := Vector3.ZERO
var grapple_attached := false
var impact_normal := Vector3.ZERO


func launch(direction):
	velocity = direction * rocket_speed


func collide():
	$"Anim".play("Explosion")
	$"Explosion".scale = Vector3.ONE * explosion_radius
	$"Rocket".visible = false
	$"Shape".disabled = true
	velocity = Vector3.ZERO


func grapple_attach():
	grapple_attached = true
	$"DestroyTimer".paused = true


func grapple_detach():
	grapple_attached = false
	$"DestroyTimer".paused = false


func _physics_process(_delta):
	if velocity == Vector3.ZERO: return
		
	if !grapple_attached:
		move_and_slide(velocity)
	
	$"Rocket/SpeedHalo".pixel_size = 0.000104167 * velocity.length()
	if get_slide_count() > 0:
		impact_normal = get_slide_collision(0).normal
		collide()


func _on_Explosion_body_entered(body):
	if "velocity" in body:
		var knockback_power = (explosion_radius - body.global_translation.distance_to(global_translation)) / explosion_radius * explosion_power
		var knockback_direction = global_translation.direction_to(body.global_translation)
		body.velocity += body.velocity * body.velocity.normalized().dot(knockback_direction)
		body.velocity += knockback_direction * knockback_power
		body.velocity += impact_normal * explosion_power_normal

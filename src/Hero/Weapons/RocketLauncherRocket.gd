extends KinematicBody


export var rocket_speed := 6.0
export var explosion_power := 12.0

var velocity := Vector3.ZERO
var grapple_attached := false


func launch(direction):
	velocity = direction * rocket_speed


func collide():
	$"Anim".play("Explosion")
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
	
	if get_slide_count() > 0:
		collide()


func _on_Explosion_body_entered(body):
	if "velocity" in body:
		var knockback_power = (3 - body.global_translation.distance_to(global_translation)) * explosion_power
		body.velocity += global_translation.direction_to(body.global_translation) * knockback_power

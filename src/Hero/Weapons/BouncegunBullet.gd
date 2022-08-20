extends KinematicBody


export var speed := 24.0
export var hit_knockback := 16.0
export var bounce_gravity := 18.0
export var bounce_count := 2

var velocity := Vector3.ZERO
var has_bounced := false


func launch(direction):
	velocity = direction * speed


func _physics_process(delta):
	if velocity == Vector3.ZERO: return
	
	if has_bounced:
		velocity.y -= bounce_gravity * delta
	
	move_and_slide(velocity)
	
	if get_slide_count() > 0:
		has_bounced = true
		bounce_count -= 1
		for i in get_slide_count():
			var col = get_slide_collision(i)
			var collider = col.collider
			if "velocity" in collider:
				collider.velocity += velocity.normalized() * hit_knockback
			
			velocity = velocity.bounce(col.normal)
			
		if bounce_count < 0:
			queue_free()

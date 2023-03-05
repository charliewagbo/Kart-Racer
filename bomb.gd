extends RigidBody3D
const Explosion = preload("res://explosion.tscn")

var initial_direction = Vector3(0,0,1)
# Called when the node enters the scene tree for the first time.
func _ready():
	linear_velocity = initial_direction * 40.0 + Vector3(0,30.0,0)

func _process(delta):
	var contact = get_contact_count()
	if contact > 0:
		explode()

func explode():
	Explosion.instantiate()
	var explosion = Explosion.instantiate()
	explosion.set_global_position(global_position)
	add_sibling(explosion)
	queue_free()

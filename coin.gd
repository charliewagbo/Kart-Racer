extends Area3D

@onready var mesh = $MeshInstance3D
@onready var particles = $GPUParticles3D
@onready var timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_y(0.03)


func _on_body_entered(body):
	if body.name == 'Ball':
		particles.emitting = true
		mesh.visible = false
		timer.start()
		body.get_parent().get_coin()


func _on_timer_timeout():
	queue_free()

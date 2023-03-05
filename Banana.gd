extends Area3D
@onready var mesh = $Mesh
@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _on_body_entered(body):
	if body.name == 'Ball':
		mesh.visible = false
		timer.start()
		body.get_parent().hit_by_item()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	queue_free()

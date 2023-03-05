extends Area3D
@onready var timer = $Timer

func _ready():
	timer.start()
# Called when the node enters the scene tree for the first time.
func _on_body_entered(body):
	if body.name == 'Ball':
		timer.start()
		body.get_parent().hit_by_item()

func _on_timer_timeout():
	queue_free()

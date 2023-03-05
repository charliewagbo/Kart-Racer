extends Area3D

func _on_body_entered(body):
	if body.name == 'Ball':
		body.get_parent().out_of_bounds()

extends Area3D

var active = true

func _process(delta):
	active =! has_overlapping_bodies()

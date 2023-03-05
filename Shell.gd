extends Area3D
@onready var move = $Move
@onready var mesh = $Mesh
@onready var timer = $Timer
@onready var hit_box = $HitBox

var initial_direction = Vector3(0,0,1)
# Called when the node enters the scene tree for the first time.
func _ready():
	move.linear_velocity = initial_direction * 30.0

func _on_body_entered(body):
	if body.name == 'Ball':
		mesh.visible = false
		timer.start()
		body.get_parent().hit_by_item()
		
func _process(delta):
	mesh.global_transform = move.global_transform
	mesh.global_rotation = Vector3(0,0,0)
	hit_box.global_transform = mesh.global_transform

func _on_timer_timeout():
	queue_free()

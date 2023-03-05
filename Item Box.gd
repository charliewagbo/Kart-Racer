extends Area3D

@onready var mesh = $MeshInstance3D
@onready var particles = $GPUParticles3D
signal get_item
@onready var burst_timer = $BurstTimer
@onready var respawn_timer = $RespawnTimer
var active = true


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_y(0.03)


func _on_body_entered(body):
	if not active: return
	if body.name == 'Ball':
		particles.emitting = true
		mesh.visible = false
		burst_timer.start()
		respawn_timer.start()
		body.get_parent().get_item()
		active = false

func _on_timer_timeout():
	particles.emitting = false

func _on_respawn_timer_timeout():
	mesh.visible = true
	active = true

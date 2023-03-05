extends Area3D

@onready var mesh = $MeshInstance3D
@onready var particles = $GPUParticles3D
@onready var burst_timer = $BurstTimer
@onready var respawn_timer = $RespawnTimer
@onready var one_time_timer = $OneTimeTimer
var active = true
var onetime = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if onetime: one_time_timer.start()

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
		body.get_parent().get_coin()
		active = false

func _on_timer_timeout():
	particles.emitting = false
	if onetime: queue_free()

func _on_respawn_timer_timeout():
	mesh.visible = true
	active = true


func _on_one_time_timer_timeout():
	queue_free()

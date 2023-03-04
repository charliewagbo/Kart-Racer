extends Node3D

@onready var ball = $Ball
@onready var mesh = $Model
@onready var ground_ray = $Model/RayCast3D
@onready var camera = $Model/Camera3D
@onready var wheel_front_left = $Model/Mesh/wheel_frontLeft
@onready var wheel_front_right = $Model/Mesh/wheel_frontRight
@onready var body = $Model/Mesh/body
@onready var speed = $HUD/MarginContainer/Speed
@onready var item_sprite = $HUD/MarginContainer/item
@onready var boost_timer = $Boost
@onready var smoke_right = $Model/Mesh/Particles/RightTyre
@onready var smoke_left = $Model/Mesh/Particles/LeftTyre
@onready var boost_particles = $Model/Mesh/Particles/Boost

#positioning relative to the colision shape
var sphere_offset = Vector3(0, -1.0,0)
@export var acceleration = 50
@export var steering = 21
@export var turn_speed = 5
@export var turn_stop_limit = 0.75
#extent of tilt on corners
@export var body_tilt = 35
#item type, currently 0 = none boost = 1
var boosting = false
@export var boost = 50
@onready var hud = $HUD

#settup input variables
var speed_input = 0
var rotate_input = 0
var boost_current = 0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	hud.visible = true


func _physics_process(delta):
	if not is_multiplayer_authority(): return
	mesh.transform.origin = ball.transform.origin + sphere_offset
	# Calc Acceleration
	ball.apply_central_force(-mesh.global_transform.basis.z * (speed_input + boost_current))

func _process(delta):
	if not is_multiplayer_authority(): return
	if not ground_ray.is_colliding():
		return
	speed_input = 0
	speed_input += Input.get_action_strength('up')
	speed_input -= Input.get_action_strength('down')
	speed_input *= acceleration
	rotate_input = 0
	rotate_input += Input.get_action_strength('left')
	rotate_input -= Input.get_action_strength('right')
	rotate_input *= deg_to_rad(steering)
	speed.text = "%s MPH" % str(round(ball.linear_velocity.length()))
	
	wheel_front_right.rotation.y = rotate_input
	wheel_front_left.rotation.y = rotate_input
	
	if ball.linear_velocity.length() > turn_stop_limit:
		var new_basis = mesh.global_transform.basis.rotated(mesh.global_transform.basis.y, rotate_input)
		mesh.global_transform.basis = mesh.global_transform.basis.slerp(new_basis, turn_speed * delta)
		
		var t = rotate_input * ball.linear_velocity.length() / body_tilt
		body.rotation.z = lerp(body.rotation.z, t, 10 * delta)
		if t > 0.2 or t < -0.2:
			smoke_left.emitting = true
			smoke_right.emitting = true
		else:
			smoke_left.emitting = false
			smoke_right.emitting = false
	
	var n = ground_ray.get_collision_normal()
	var xform = align_with_y(mesh.global_transform, n)
	mesh.global_transform = mesh.global_transform.interpolate_with(xform, 10 * delta)
	
func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
	
func get_item():
	item_sprite.frame = 1


func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("reset"):
		print('reset')
	if Input.is_action_just_pressed("use_item"):
		if item_sprite.frame == 1:
			boost_current = boost
			boost_particles.emitting = true
			boost_timer.start()
		item_sprite.frame = 0


func _on_boost_timeout():
	boost_current = 0
	boost_particles.emitting = false

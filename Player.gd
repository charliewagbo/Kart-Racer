extends Node3D
const Banana = preload("res://banana.tscn")
const Shell = preload("res://shell.tscn")
const Bomb = preload("res://bomb.tscn")
@onready var ball = $Ball
@onready var mesh = $Model
@onready var model = $Model/Mesh
@onready var ground_ray = $Model/RayCast3D
@onready var camera = $Model/SpringArm3D/Camera3D
@onready var wheel_front_left = $Model/Mesh/wheel_frontLeft
@onready var wheel_front_right = $Model/Mesh/wheel_frontRight
@onready var body = $Model/Mesh/body
@onready var speed = $HUD/MarginContainer/Speed
@onready var item_sprite = $HUD/MarginContainer/item
@onready var boost_timer = $Boost
@onready var smoke_right = $Model/Mesh/Particles/RightTyre
@onready var smoke_left = $Model/Mesh/Particles/LeftTyre
@onready var boost_particles = $Model/Mesh/Particles/Boost
@onready var colision_timer = $Colision
@onready var sync = $sync
@onready var nametag = $Model/Nametag
@onready var coins_display = $HUD/MarginContainer/Coins
@onready var spring_arm_3d = $Model/SpringArm3D
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
var coins = 0
var frozen = false

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	hud.visible = true

func set_player_name(name):
	nametag.text = name

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	mesh.transform.origin = ball.transform.origin + sphere_offset
	# Calc Acceleration
	if not frozen:
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
	if frozen:
		model.rotate_y(0.5)
	if ball.linear_velocity.length() > turn_stop_limit and not frozen:
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

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("reset"):
		print('you need to make reset work pal')
	#Long ass code to handle using items, some duplication
	if Input.is_action_just_pressed("use_item"):
		
		#Handle boost items
		if item_sprite.frame == 1:
			boost_current = boost
			boost_particles.emitting = true
			boost_timer.start()
			item_sprite.frame = 0
			return
		if item_sprite.frame == 4:
			boost_current = boost
			boost_particles.emitting = true
			boost_timer.start()
			item_sprite.frame = 9
			return
		if item_sprite.frame == 9:
			boost_current = boost
			boost_particles.emitting = true
			boost_timer.start()
			item_sprite.frame = 1
			return
		
		#Handle Banana Items
		if item_sprite.frame == 2:
			drop_item.rpc('banana')
			item_sprite.frame = 0
			return
		if item_sprite.frame == 6:
			drop_item.rpc('banana')
			item_sprite.frame = 10
			return
		if item_sprite.frame == 10:
			drop_item.rpc('banana')
			item_sprite.frame = 2
			return
		
		#Handle Shell Items
		if item_sprite.frame == 3:
			drop_item.rpc('shell')
			item_sprite.frame = 0
			return
		if item_sprite.frame == 5:
			drop_item.rpc('shell')
			item_sprite.frame = 11
			return
		if item_sprite.frame == 11:
			drop_item.rpc('shell')
			item_sprite.frame = 3
			return
		
		#Handle bomb
		if item_sprite.frame == 7:
			drop_item.rpc('bomb')
			item_sprite.frame = 0
			return

func get_item():
	if item_sprite.frame == 0:
		item_sprite.frame =  randi() % 7 + 1

func get_coin():
	coins = coins + 1
	coins_display.text = str(coins)
	

func hit_by_item():
	frozen = true
	#ball.freeze = true
	ball.linear_velocity = Vector3(0,0,0)
	colision_timer.start()

func _on_boost_timeout():
	boost_current = 0
	boost_particles.emitting = false


func _on_colision_timeout():
	frozen = false
	model.global_rotation = mesh.global_rotation
	#ball.freeze = false

@rpc("call_local")
func drop_item(type):
	if type == 'banana':
		Banana.instantiate()
		var banana = Banana.instantiate()
		banana.set_global_position(mesh.global_position + Vector3(0,0.5,0) + 2 * mesh.global_transform.basis.z)
		add_sibling(banana)
	if type == 'shell':
		Shell.instantiate()
		var shell = Shell.instantiate()
		shell.set_global_position(mesh.global_position + Vector3(0,0.5,0) - 3 * mesh.global_transform.basis.z)
		shell.initial_direction = -mesh.global_transform.basis.z
		add_sibling(shell)
	if type == 'bomb':
		Bomb.instantiate()
		var bomb = Bomb.instantiate()
		bomb.set_global_position(mesh.global_position + Vector3(0,1,0) - 3 * mesh.global_transform.basis.z)
		bomb.initial_direction = -mesh.global_transform.basis.z
		add_sibling(bomb)

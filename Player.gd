extends Node3D
const Banana = preload("res://banana.tscn")
const Shell = preload("res://shell.tscn")
const Bomb = preload("res://bomb.tscn")
const Coin = preload("res://coin.tscn")
const ready_sprite = preload("res://sprites/ready.png")
const unready_sprite = preload("res://sprites/unready.png")
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
@onready var out_of_bounds_correction = $OutOfBoundsCorrection
@onready var join_correction = $JoinCorrection
@onready var nametag = $Model/Nametag
@onready var coins_display = $HUD/MarginContainer/Coins
@onready var spring_arm_3d = $Model/SpringArm3D
@onready var name_entry = $"HUD/Start Menu/MarginContainer/VBoxContainer/Name Entry"
@onready var start_menu = $"HUD/Start Menu"
@onready var ready_menu = $HUD/ReadyMenu
@onready var ready_list = $HUD/ReadyMenu/MarginContainer/VBoxContainer/ReadyList
@onready var ready_title = $HUD/ReadyMenu/MarginContainer/VBoxContainer/ReadyTitle
@onready var start_timer = $StartTimer
@onready var game_clock_text = $HUD/MarginContainer/GameClockText
@onready var crown = $Model/Mesh/Crown
@onready var message = $HUD/Message
@onready var message_timer = $MessageTimer
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
@onready var hud = $HUD/MarginContainer
#settup input variables
var speed_input = 0
var rotate_input = 0
var boost_current = 0
@export var coins = 0
@export var user_name = 'New Player'
@export var player_ready = false
@export var in_game = false
@export var spectating = false
var frozen = false
var in_menu = true
var current_spectated_player = null
var current_spectated_player_index = 0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	camera.current = true
	hud.visible = true
	start_menu.visible = true
	nametag.visible = false
	join_correction.start()

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	mesh.transform.origin = ball.transform.origin + sphere_offset
	# Calc Acceleration
	if not frozen and not in_menu:
		ball.apply_central_force(-mesh.global_transform.basis.z * (speed_input + boost_current))

func _process(delta):
	if not is_multiplayer_authority(): return
	if in_game:
		_check_winning()
		_check_game_time()
	if not in_game: _get_ready_players()
	game_clock_text.text = str(round(get_parent().get_parent().find_child('GameClock').time_left))
	speed_input -= Input.get_action_strength('down')
	if spectating:
		if not _check_game_in_progress():
			spectating = false
			model.visible = true
			start_menu.visible = true
			hud.visible = true
			message.text = ''
			current_spectated_player.find_child('HUD').find_child('MarginContainer').visible = false
			_game_over()
			ball.freeze = false
		if current_spectated_player != null:
			mesh.global_transform = current_spectated_player.find_child('Model').global_transform
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
	if ball.linear_velocity.length() > turn_stop_limit and not frozen and not in_menu:
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
		if spectating:
			change_spectated_player()
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
	if coins == 0:
		return
	if coins == 1:
		drop_coin.rpc(1)
		coins = coins - 1
		coins_display.text = str(coins)
	if coins == 2:
		drop_coin.rpc(2)
		coins = coins - 2
		coins_display.text = str(coins)
	if coins > 2:
		drop_coin.rpc(3)
		coins = coins - 3
		coins_display.text = str(coins)

func _on_boost_timeout():
	boost_current = 0
	boost_particles.emitting = false


func _on_colision_timeout():
	frozen = false
	model.global_rotation = mesh.global_rotation
	#ball.freeze = false

@rpc("call_local")
func drop_item(type):
	var items = get_parent()
	if type == 'banana':
		Banana.instantiate()
		var banana = Banana.instantiate()
		banana.set_global_position(mesh.global_position + Vector3(0,0.5,0) + 2 * mesh.global_transform.basis.z)
		items.add_sibling(banana)
	if type == 'shell':
		Shell.instantiate()
		var shell = Shell.instantiate()
		shell.set_global_position(mesh.global_position + Vector3(0,0.5,0) - 3 * mesh.global_transform.basis.z)
		shell.initial_direction = -mesh.global_transform.basis.z
		items.add_sibling(shell)
	if type == 'bomb':
		Bomb.instantiate()
		var bomb = Bomb.instantiate()
		bomb.set_global_position(mesh.global_position + Vector3(0,1,0) - 3 * mesh.global_transform.basis.z)
		bomb.initial_direction = -mesh.global_transform.basis.z
		items.add_sibling(bomb)

@rpc("call_local")
func drop_coin(number):
	var items = get_parent()
	Coin.instantiate()
	var coin = Coin.instantiate()
	coin.set_global_position(mesh.global_position + Vector3(0,1,0) + 4 * mesh.global_transform.basis.z)
	coin.rotation = Vector3(90,0,90)
	coin.onetime = true
	items.add_sibling(coin)
	if number > 1:
		var coin2 = Coin.instantiate()
		coin2.set_global_position(mesh.global_position + Vector3(0,1,0) + 4 * mesh.global_transform.basis.z.rotated(Vector3(0,1,0),2.09))
		coin2.rotation = Vector3(90,0,90)
		coin2.onetime = true
		items.add_sibling(coin2)
	if number > 2:
		var coin3 = Coin.instantiate()
		coin3.set_global_position(mesh.global_position + Vector3(0,1,0) + 4 * mesh.global_transform.basis.z.rotated(Vector3(0,1,0),-2.09))
		coin3.rotation = Vector3(90,0,90)
		coin3.onetime = true
		items.add_sibling(coin3)

func out_of_bounds():
	player_spawn()
	out_of_bounds_correction.start()

func player_spawn():
	var spawn_points = get_parent().get_parent().find_child('SpawnPoints').get_children()
	var nearest_spawn_point = spawn_points[0]
	for spawn_point in spawn_points:
		if spawn_point.active:
			if spawn_point.global_position.distance_to(ball.global_position) < nearest_spawn_point.global_position.distance_to(ball.global_position):
				nearest_spawn_point = spawn_point
	ball.global_position = nearest_spawn_point.global_position

func _on_out_of_bounds_correction_timeout():
	hit_by_item()

func _on_join_correction_timeout():
	if _check_game_in_progress():
		_start_spectating()
	else: player_spawn()
		

func _on_go_pressed():
	nametag.text = name_entry.text
	user_name = name_entry.text
	start_menu.visible = false
	if !spectating:
		ready_menu.visible = true

func _get_ready_players():
	ready_list.clear()
	var players = get_parent().get_children()
	var all_ready = true
	for player in players:
		if player.player_ready:
			ready_list.add_item(player.user_name,ready_sprite)
		else:
			ready_list.add_item(player.user_name,unready_sprite)
			all_ready = false
	if all_ready:
		_all_ready()

func _on_ready_pressed():
	if player_ready: player_ready = false
	else: player_ready = true

func _all_ready():
	ready_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	in_menu = false
	var game_clock = get_parent().get_parent().find_child('GameClock')
	if game_clock.time_left == 0:
		game_clock.start()
		in_game = true
		return
	
func _check_winning():
	if coins > 0:
		var players = get_parent().get_children()
		var winning_player = players[0]
		for player in players:
			if player.coins > winning_player.coins:
				winning_player = player
		if winning_player.name == name:
			crown.visible = true
		else: crown.visible = false
	else: crown.visible = false

func _check_game_in_progress():
	var game_in_progress = false
	var players = get_parent().get_children()
	for player in players:
		if player.in_game:
			game_in_progress = true
	if game_in_progress: return true
	else: return false

func _start_spectating():
	ball.global_translate(Vector3(0,500,0))
	ball.freeze = true
	spectating = true
	model.visible = false
	start_menu.visible = false
	hud.visible = false
	message.text = 'Spectating...'
	change_spectated_player()

func change_spectated_player():
	var players = get_parent().get_children()
	var in_game_players = []
	for player in players:
		if player.in_game:
			in_game_players.append(player)
	if current_spectated_player == null:
		current_spectated_player = in_game_players[0]
	else:
		current_spectated_player.find_child('HUD').find_child('MarginContainer').visible = false
		current_spectated_player_index = current_spectated_player_index+1
		if current_spectated_player_index > in_game_players.size()-1:
			current_spectated_player_index = 0
		current_spectated_player = in_game_players[current_spectated_player_index]
	in_game_players = []
	current_spectated_player.find_child('HUD').find_child('MarginContainer').visible = true
	return

func _game_over():
	if in_game:
		player_ready = false
		var players = get_parent().get_children()
		var winning_player = players[0]
		for player in players:
			if player.coins > winning_player.coins:
				winning_player = player
		if winning_player.name == name:
			message.text = 'You Win!'
		else: message.text = '%s Wins!' % winning_player.user_name
		if message_timer.is_stopped(): message_timer.start()

func _check_game_time():
	var game_clock = get_parent().get_parent().find_child('GameClock')
	if game_clock.time_left == 0:
		_game_over()


func _on_message_timer_timeout():
	message.text = ''
	coins = 0
	coins_display.text = coins
	item_sprite.frame = 0
	player_spawn()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ready_menu.visible = true
	in_menu = true
	in_game = false

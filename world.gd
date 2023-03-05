extends Node

@onready var main_menu = $"CanvasLayer/Main Menu"
@onready var address_entry = $"CanvasLayer/Main Menu/MarginContainer/VBoxContainer/Adress Entry"
@onready var scoreboard = $Scoreboard

const Player = preload("res://player.tscn")
const PORT = 9421
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())
	upnp_settup()

func _on_join_button_pressed():
	main_menu.hide()
	enet_peer.create_client(address_entry.text,PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	scoreboard.player_names.append(str(peer_id))

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func upnp_settup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
		
	var upnpresult = upnp.get_gateway()
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway! %s" %upnpresult)
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join at: %s" % upnp.query_external_address())


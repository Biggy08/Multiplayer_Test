#Game Node Script
extends Node

@onready var multiplayer_ui = $UI/Multiplayer
const PLAYER = preload("res://scenes/game/player.tscn")
var peer = ENetMultiplayerPeer.new()

func _on_host_pressed() -> void:
	$sound_click.play()
	print(" GAME has been HOSTED")
	peer.create_server(8848)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(
	func(pid):
		print("PLAYER  " + str(pid) + " has JOINED ")
		add_player(pid)		#spawn player for client
		)
		
	add_player(multiplayer.get_unique_id()) #spawn player for host
	multiplayer_ui.hide()


func _on_join_pressed() -> void:
	
	$sound_click.play()
	peer.create_client("localhost",8848)
	multiplayer.multiplayer_peer = peer
	multiplayer_ui.hide()

# Instantiate Player
func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)     #naming the player
	add_child(player)
	
	print_stack()

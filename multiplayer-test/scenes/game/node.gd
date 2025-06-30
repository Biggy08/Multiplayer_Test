extends Node

@onready var multiplayer_ui = $UI/Multiplayer
const PLAYER = preload("res://scenes/game/player.tscn")
var peer = ENetMultiplayerPeer.new()

var players: Array[Player] = []

func _ready():
	$MultiplayerSpawner.spawn_function = add_player

# =============================
# When HOST is pressed
# =============================
func _on_host_pressed() -> void:
	$sound_click.play()
	print(" GAME has been HOSTED")

	# Start the server on port 8848
	peer.create_server(8848)
	multiplayer.multiplayer_peer = peer

	# Handle player joining
	multiplayer.peer_connected.connect(func(pid):
		print("PLAYER " + str(pid) + " has JOINED")
		$MultiplayerSpawner.spawn(pid)  # Spawn new player's avatar
	)

	# Handle player leaving
	multiplayer.peer_disconnected.connect(func(pid):
		print("PLAYER " + str(pid) + " has LEFT")
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()
			players = players.filter(func(p): return p.name != str(pid))

	)

	# Add the host's own player
	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())

	# Hide UI
	multiplayer_ui.hide()


# =============================
# When JOIN is pressed
# =============================
func _on_join_pressed() -> void:
	$sound_click.play()
	# Connect to server (host) at localhost:8848
	peer.create_client("localhost", 8848)
	multiplayer.multiplayer_peer = peer

	# Handle other players disconnecting
	multiplayer.peer_disconnected.connect(func(pid):
		print("PLAYER " + str(pid) + " has LEFT")
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()
			players = players.filter(func(p): return p.name != str(pid))

	)

	# Handle disconnection from the host
	multiplayer.server_disconnected.connect(func():
		print("Disconnected from host")
		show_host_disconnected_message()  # Show popup and return to menu
	)

	# Hide UI
	multiplayer_ui.hide()



# =============================
# Add a player to the scene
# =============================
func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)  # Name node by player ID
	
	player.global_position= $TextureRect/Lobby.get_child(players.size()).global_position
	players.append(player)
	return player
	



func get_safe_unique_id():
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	else:
		print("Warning: multiplayer peer not active.")
		return -1  # or null





# =============================
# Show message when host disconnects
# =============================
func show_host_disconnected_message():
	print("Host disconnected — multiplayer is no longer active.")

	var popup = AcceptDialog.new()
	popup.dialog_text = "Host disconnected. Returning to menu."
	add_child(popup)
	popup.popup_centered()

	popup.confirmed.connect(func():
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
	
	)


# =============================
# When BACK is pressed (leave game)
# =============================
func _on_back_pressed() -> void:
	$sound_click.play()
	var pid = get_safe_unique_id()
	if pid != -1:
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()

	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

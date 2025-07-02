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

	peer.create_server(8848)
	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(func(pid):
		print("PLAYER " + str(pid) + " has JOINED")
		$MultiplayerSpawner.spawn(pid)
	)

	multiplayer.peer_disconnected.connect(func(pid):
		print("PLAYER " + str(pid) + " has LEFT")
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()
			players = players.filter(func(p): return p.name != str(pid))
	)

	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())

	# ✅ Show host IP in HostIPLabel (safe for Godot 4)
	var ip_list = IP.get_local_addresses()
	var lan_ip = ""
	for ip in ip_list:
		if ip.begins_with("192.") or ip.begins_with("10.") or ip.begins_with("172."):
			lan_ip = ip
			break

	var ip_text = "IP not found"
	if lan_ip != "":
		ip_text = "Your IP: " + lan_ip

	multiplayer_ui.get_node("MarginContainer/VBoxContainer/HostIPLabel").text = ip_text

# =============================
# When JOIN is pressed
# =============================
func _on_join_pressed() -> void:
	$sound_click.play()

	var ip_address = multiplayer_ui.get_node("MarginContainer/VBoxContainer/HostIPField").text.strip_edges()
	if ip_address == "":
		ip_address = "192.168.1.5"  # fallback for test

	print("Trying to connect to host at: ", ip_address)
	peer.create_client(ip_address, 8848)
	multiplayer.multiplayer_peer = peer

	multiplayer.peer_disconnected.connect(func(pid):
		print("PLAYER " + str(pid) + " has LEFT")
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()
			players = players.filter(func(p): return p.name != str(pid))
	)

	multiplayer.server_disconnected.connect(func():
		print("Disconnected from host")
		show_host_disconnected_message()
	)

	multiplayer_ui.hide()

# =============================
# Add a player to the scene
# =============================
func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	player.global_position = $TextureRect/Lobby.get_child(players.size()).global_position
	players.append(player)
	return player

# =============================
# Get Unique ID (safe)
# =============================
func get_safe_unique_id():
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	else:
		print("Warning: multiplayer peer not active.")
		return -1

# =============================
# Host disconnected popup
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
# BACK Button
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

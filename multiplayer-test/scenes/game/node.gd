class_name Game
extends Node

@onready var multiplayer_ui = $UI/Multiplayer
@onready var host_ip_label = $UI/HostIPLabel
const PLAYER = preload("res://scenes/game/player.tscn")
var peer = ENetMultiplayerPeer.new()
var players: Array[Player] = []

func _ready():
	$MultiplayerSpawner.spawn_function = add_player
	host_ip_label.hide() 

# Get Valid LAN IP (Android + PC)

func get_valid_lan_ip() -> String:
	var valid_ips = []
	for ip in IP.get_local_addresses():
		if ip.is_valid_ip_address() and not ip.begins_with("127.") and ip.find(":") == -1:
			if ip.begins_with("192.") or ip.begins_with("10.") or ip.begins_with("172."):
				valid_ips.append(ip)

	if valid_ips.size() > 0:
		print("Valid LAN IPs: ", valid_ips)
		return valid_ips[0]
	else:
		print("No valid LAN IP found. All IPs: ", IP.get_local_addresses())
		return "IP_NOT_FOUND"


# HOST
func _on_host_pressed() -> void:
	$sound_click.play()
	print("🎮 GAME HOSTED")

	peer.create_server(8848)
	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(func(pid):
		print(" PLAYER JOINED: ", pid)
		$MultiplayerSpawner.spawn(pid)
	)

	multiplayer.peer_disconnected.connect(func(pid):
		print("PLAYER LEFT: ", pid)
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()
			players = players.filter(func(p): return p.name != str(pid))
	)

	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())

	# 🖥 Show Host IP
	var ip = get_valid_lan_ip()
	print(" Host LAN IP: ", ip)
	host_ip_label.text = " IP not found!" if ip == "IP_NOT_FOUND" else "📡 Your IP: " + ip
	host_ip_label.show()

	multiplayer_ui.hide()
	
#  JOIN
func _on_join_pressed() -> void:
	$sound_click.play()

	var input_field = multiplayer_ui.get_node("MarginContainer/VBoxContainer/HostIPField")
	var ip_address = input_field.text.strip_edges()
	if ip_address == "":
		ip_address = "192.168.1.5"  # Fallback for test

	print("🔌 Connecting to host at: ", ip_address)

	peer.create_client(ip_address, 8848)
	multiplayer.multiplayer_peer = peer

	multiplayer.peer_disconnected.connect(func(pid):
		print("❌ PLAYER LEFT: ", pid)
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()
			players = players.filter(func(p): return p.name != str(pid))
	)

	multiplayer.server_disconnected.connect(func():
		print("🔌 Disconnected from host")
		show_host_disconnected_message()
	)

	multiplayer_ui.hide()
	host_ip_label.hide() 

# SPAWN PLAYER
func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	player.global_position = $TextureRect/Lobby.get_child(players.size()).global_position
	players.append(player)
	return player


#  Get Safe Unique ID
func get_safe_unique_id():
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return -1


# Host Disconnected Popup

func show_host_disconnected_message():
	var popup = AcceptDialog.new()
	popup.dialog_text = "Host disconnected. Returning to menu."
	add_child(popup)
	popup.popup_centered()

	popup.confirmed.connect(func():
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
	)


# BACK Button

func _on_back_pressed() -> void:
	$sound_click.play()
	var pid = get_safe_unique_id()
	if pid != -1:
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()

	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

#Spawning
func get_random_spawnpoint():
	return $TextureRect/Lobby.get_children().pick_random().global_position

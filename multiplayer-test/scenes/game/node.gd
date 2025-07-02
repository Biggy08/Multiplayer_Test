extends Node

@onready var multiplayer_ui = $UI/Multiplayer
const PLAYER = preload("res://scenes/game/player.tscn")
var peer = ENetMultiplayerPeer.new()
var players: Array[Player] = []

func _ready():
	$MultiplayerSpawner.spawn_function = add_player

# =========================================
# 🔧 Get Valid LAN IP (Works on Android + PC)
# =========================================
func get_valid_lan_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "IP_NOT_FOUND"

# =========================================
# 🎮 HOST
# =========================================
func _on_host_pressed() -> void:
	$sound_click.play()
	print("🎮 GAME HOSTED")

	peer.create_server(8848)
	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(func(pid):
		print("✅ PLAYER JOINED: ", pid)
		$MultiplayerSpawner.spawn(pid)
	)

	multiplayer.peer_disconnected.connect(func(pid):
		print("❌ PLAYER LEFT: ", pid)
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()
			players = players.filter(func(p): return p.name != str(pid))
	)

	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())

	# 🖥 Show Host IP
	var ip = get_valid_lan_ip()
	var label = multiplayer_ui.get_node("MarginContainer/VBoxContainer/HostIPLabel")
	label.text = "IP not found!" if ip == "IP_NOT_FOUND" else "Your IP: " + ip

# =========================================
# 🤝 JOIN
# =========================================
func _on_join_pressed() -> void:
	$sound_click.play()

	var input_field = multiplayer_ui.get_node("MarginContainer/VBoxContainer/HostIPField")
	var ip_address = input_field.text.strip_edges()
	if ip_address == "":
		ip_address = "192.168.1.5"  # default test IP if left blank

	print("🌐 Connecting to host at: ", ip_address)

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
		print("🚫 Disconnected from host")
		show_host_disconnected_message()
	)

	multiplayer_ui.hide()

# =========================================
# 🧍‍♂️ SPAWN PLAYER
# =========================================
func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	player.global_position = $TextureRect/Lobby.get_child(players.size()).global_position
	players.append(player)
	return player

# =========================================
# 🔑 Get Safe Unique ID
# =========================================
func get_safe_unique_id():
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return -1

# =========================================
# ❌ Host Disconnected Popup
# =========================================
func show_host_disconnected_message():
	var popup = AcceptDialog.new()
	popup.dialog_text = "Host disconnected. Returning to menu."
	add_child(popup)
	popup.popup_centered()

	popup.confirmed.connect(func():
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
	)

# =========================================
# 🔙 BACK Button
# =========================================
func _on_back_pressed() -> void:
	$sound_click.play()
	var pid = get_safe_unique_id()
	if pid != -1:
		var player_node = get_node_or_null(str(pid))
		if player_node:
			player_node.queue_free()

	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

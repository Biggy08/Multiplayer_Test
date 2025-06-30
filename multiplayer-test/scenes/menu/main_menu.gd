extends Node2D

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/node.tscn")


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	pass

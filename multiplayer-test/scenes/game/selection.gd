extends Control

# Map Selection 


func _on_map_1_pressed() -> void:
	AudioManager.Click.play()
	GameManager.selected_map_path = "res://scenes/maps/Map1.tscn"
	GameManager.load_selected_map()
	



func _on_map_2_pressed() -> void:
	AudioManager.Click.play()
	GameManager.selected_map_path= "res://scenes/maps/Map2.tscn"
	GameManager.load_selected_map()
	
	

func _on_back_pressed() -> void:
	AudioManager.Click.play()
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
	

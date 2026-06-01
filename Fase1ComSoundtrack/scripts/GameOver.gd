extends Control
## Tela de Game Over

func _on_retry_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Fase1.tscn")

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

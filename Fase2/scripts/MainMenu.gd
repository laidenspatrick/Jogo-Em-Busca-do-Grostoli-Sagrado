extends Control
## Menu Principal

func _on_play_button_pressed():
	GameManager.player_hp = 100   # começa sempre com vida cheia
	get_tree().change_scene_to_file("res://scenes/Fase1.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

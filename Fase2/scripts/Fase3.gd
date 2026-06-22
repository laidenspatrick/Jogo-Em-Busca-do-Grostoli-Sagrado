extends Node

func _ready() -> void:
	$UI/BtnVoltar.pressed.connect(_on_voltar)

func _on_voltar() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

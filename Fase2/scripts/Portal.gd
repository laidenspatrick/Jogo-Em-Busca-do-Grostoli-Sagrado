extends Area2D
## Portal de transição entre fases

@export var target_scene: String = "res://scenes/Fase2.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_animate()

func _animate() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property($InnerGlow, "modulate", Color(0.5, 1.0, 1.0, 0.5), 0.7)
	tween.tween_property($InnerGlow, "modulate", Color(0.8, 0.95, 1.0, 1.0), 0.7)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(target_scene)

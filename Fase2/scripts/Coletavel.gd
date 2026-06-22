extends Area2D
## Item de coleta — Metal ou Madeira (Fase 2)
## Usado para reconstruir a plataforma/pier de Atlântida (10 de cada)

@export var item_type: String = "metal"  # "metal" ou "madeira"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_float_animation()

func _float_animation() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 6, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y + 6, 0.9).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var controllers = get_tree().get_nodes_in_group("level_controller")
	if controllers.size() > 0 and controllers[0].has_method("collect_item"):
		controllers[0].collect_item(item_type)
	queue_free()

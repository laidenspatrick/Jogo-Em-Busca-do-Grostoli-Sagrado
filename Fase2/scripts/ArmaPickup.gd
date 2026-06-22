extends Area2D
## Pickup de arma — desbloqueia o Estilingue de Pinhão para o jogador

@export var weapon_id: String = "estilingue"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate", Color(1.3, 1.3, 0.5, 1.0), 0.7)
	tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.2, 1.0), 0.7)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("unlock_weapon"):
		body.unlock_weapon(weapon_id)
		var controllers = get_tree().get_nodes_in_group("level_controller")
		if controllers.size() > 0 and controllers[0].has_method("on_weapon_unlocked"):
			controllers[0].on_weapon_unlocked(weapon_id)
		queue_free()

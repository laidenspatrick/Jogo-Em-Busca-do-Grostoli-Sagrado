extends Node2D
## Fase 1 - Centro de Porto Alegre

func _ready() -> void:
	var player = $Player
	var hud    = $HUD
	player.health_changed.connect(hud.update_health)

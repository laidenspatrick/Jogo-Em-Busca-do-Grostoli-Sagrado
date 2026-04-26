extends Node2D
## Fase 1 - Centro de Porto Alegre
## Conecta sinais do Player ao HUD

func _ready():
	var player = $Player
	var hud = $HUD
	player.health_changed.connect(hud.update_health)

extends Node2D
func _ready() -> void:
	var player = $Player
	var hud = $HUD

	player.health_changed.connect(hud.update_health)

	$Soundtrack.play()

extends Node2D

var total_pombos := 0
var pombos_defeated := 0

func _ready() -> void:
	add_to_group("level_controller")

	var player = $Player
	var hud = $HUD

	player.health_changed.connect(hud.update_health)
	player.weapon_changed.connect(hud.update_weapon)
	hud.update_health(player.current_hp)   # sincroniza vida vinda da fase anterior

	total_pombos = get_tree().get_nodes_in_group("enemies").size()
	hud.set_kill_counter_visible(true)
	hud.update_kills(0, total_pombos)

	$Soundtrack.play()

	# Dica de duplo salto logo no início da fase
	hud.show_message("Dica: pressione PULAR duas vezes no ar para o duplo salto!", 3.5)

func on_pombo_defeated() -> void:
	pombos_defeated += 1
	$HUD.update_kills(pombos_defeated, total_pombos)
	if pombos_defeated == total_pombos:
		$HUD.show_message("Todos os Pombos Raivosos foram derrotados!", 2.5)

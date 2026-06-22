extends Node2D
## Fase 2 — Litoral Gaúcho, Atlântida
## Coleta de Metal e Madeira (10 de cada) para reconstruir o pier e prosseguir.
## O caminho para a Fase 3 fica fisicamente bloqueado até a ponte ser concluída.

const REQUIRED_METAL   := 10
const REQUIRED_MADEIRA := 10

var metal_count    := 0
var madeira_count  := 0
var bridge_built    := false

func _ready() -> void:
	add_to_group("level_controller")

	var player = $Player
	var hud    = $HUD

	player.health_changed.connect(hud.update_health)
	player.weapon_changed.connect(hud.update_weapon)
	hud.update_health(player.current_hp)   # mantém a vida vinda da Fase 1

	hud.set_collectibles_visible(true)
	hud.update_metal(0, REQUIRED_METAL)
	hud.update_madeira(0, REQUIRED_MADEIRA)

	$Soundtrack.play()

	# Ponte e barreira começam bloqueando o caminho até reconstruir o pier
	$PonteFinal/CollisionShape2D.disabled = true
	$PonteFinal.visible = false
	for plank in $PonteFinal/Planks.get_children():
		plank.visible = false
		plank.position.y = -120  # fora de tela, prontas para "cair" no lugar

	$AvisoArea.body_entered.connect(_on_aviso_area_entered)

func collect_item(item_type: String) -> void:
	match item_type:
		"metal":
			metal_count = min(metal_count + 1, REQUIRED_METAL)
			$HUD.update_metal(metal_count, REQUIRED_METAL)
		"madeira":
			madeira_count = min(madeira_count + 1, REQUIRED_MADEIRA)
			$HUD.update_madeira(madeira_count, REQUIRED_MADEIRA)

	if metal_count == REQUIRED_METAL and madeira_count == REQUIRED_MADEIRA and not bridge_built:
		_build_bridge()
	elif not bridge_built:
		$HUD.show_message("Item coletado! Continue juntando Metal e Madeira.", 1.0)

func on_weapon_unlocked(weapon_id: String) -> void:
	if weapon_id == "estilingue":
		$HUD.show_message("Estilingue de Pinhão equipado! Use Q/E para trocar de arma.", 3.0)

func _build_bridge() -> void:
	bridge_built = true

	# Destroys the blocking node entirely — disabled=true alone can leave
	# the StaticBody2D registered in the physics world in Godot 4.
	var barreira_tween = create_tween()
	barreira_tween.tween_property($Barreira, "modulate:a", 0.0, 0.5)
	barreira_tween.tween_callback($Barreira.queue_free)

	$HUD.show_message("Pier reconstruído! O caminho para Atlântida está livre.", 3.0)

	$PonteFinal.visible = true

	# Animação: tábuas caem em sequência, com leve quique, + faíscas de poeira/serragem
	var planks = $PonteFinal/Planks.get_children()
	for i in range(planks.size()):
		var plank = planks[i]
		plank.visible = true
		var delay = i * 0.18
		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(plank, "position:y", 6, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(plank, "position:y", -3, 0.10).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(plank, "position:y", 0, 0.10).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(_spawn_dust.bind(plank.global_position))

	# Pequeno tremor de câmera para dar peso à reconstrução
	_camera_shake(0.4, 4.0)

	# A colisão só fica sólida quando a última tábua termina de cair
	var total_drop_time = (planks.size() - 1) * 0.18 + 0.42
	await get_tree().create_timer(total_drop_time).timeout
	$PonteFinal/CollisionShape2D.disabled = false

func _spawn_dust(at_position: Vector2) -> void:
	for i in range(5):
		var chip = Polygon2D.new()
		var size = randf_range(3.0, 6.0)
		chip.polygon = PackedVector2Array([
			Vector2(-size, -size), Vector2(size, -size),
			Vector2(size, size), Vector2(-size, size)
		])
		chip.color = Color(0.65, 0.5, 0.32, 1.0) if i % 2 == 0 else Color(0.85, 0.78, 0.55, 1.0)
		chip.global_position = at_position + Vector2(randf_range(-20, 20), randf_range(-10, 0))
		add_child(chip)
		var t = create_tween()
		var target = chip.position + Vector2(randf_range(-30, 30), randf_range(-50, -20))
		t.set_parallel(true)
		t.tween_property(chip, "position", target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(chip, "modulate:a", 0.0, 0.5)
		t.set_parallel(false)
		t.tween_callback(chip.queue_free)

func _camera_shake(duration: float, strength: float) -> void:
	var cam = $Player/Camera2D
	if not cam:
		return
	var elapsed = 0.0
	while elapsed < duration:
		cam.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	cam.offset = Vector2.ZERO

func _on_aviso_area_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not bridge_built:
		var faltam_metal   = REQUIRED_METAL - metal_count
		var faltam_madeira = REQUIRED_MADEIRA - madeira_count
		$HUD.show_message(
			"Caminho bloqueado! Faltam %d Metal e %d Madeira para reconstruir o pier." % [faltam_metal, faltam_madeira],
			2.5
		)

extends CharacterBody2D
## Pombo Raivoso - Inimigo da Fase 1
## Patrulha voando e mergulha em direção ao jogador

const FLY_SPEED   = 100.0
const DIVE_SPEED  = 300.0
const GRAVITY     = 600.0

var hp            := 30
var direction     := 1.0
var is_diving     := false
var dive_cooldown := 3.0
var dive_timer    := 2.0
var patrol_range  := 150.0
var start_position := Vector2.ZERO
var player: Node2D = null
var damage        := 12

func _ready():
	add_to_group("enemies")
	start_position = global_position
	# Encontrar jogador no próximo frame
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float):
	# ---- Mergulho ----
	if is_diving:
		velocity.y += GRAVITY * delta
		move_and_slide()
		# Retorna à posição de patrulha após mergulho
		if is_on_floor() or global_position.y > start_position.y + 200:
			is_diving = false
			velocity = Vector2.ZERO
			global_position = start_position
		return

	# ---- Patrulha voando ----
	velocity.x = direction * FLY_SPEED
	velocity.y = 0  # Voa (ignora gravidade)

	if abs(global_position.x - start_position.x) > patrol_range:
		direction *= -1

	# ---- Verificar se deve mergulhar ----
	dive_timer -= delta
	if dive_timer <= 0 and player:
		var dist = global_position.distance_to(player.global_position)
		if dist < 350:
			_start_dive()
		dive_timer = dive_cooldown

	move_and_slide()

func _start_dive():
	if not player:
		return
	is_diving = true
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * DIVE_SPEED

func take_damage(amount: int):
	hp -= amount
	# Flash vermelho
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		queue_free()

func _on_hit_box_body_entered(body: Node2D):
	if body.is_in_group("player"):
		body.take_damage(damage)

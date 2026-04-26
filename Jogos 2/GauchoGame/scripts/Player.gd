extends CharacterBody2D
## Personagem principal - Gaúcho
## Movimentação: correr, pular (duplo salto), esquivar (com i-frames)
## Combate: Espetão de Costela (melee)

# --- Movimento ---
const SPEED         = 250.0
const JUMP_VELOCITY = -420.0
const GRAVITY       = 900.0
const DODGE_SPEED   = 450.0
const DODGE_DURATION = 0.3

# --- Vida ---
var max_hp     := 100
var current_hp := 100

# --- Double Jump ---
var can_double_jump := true

# --- Dodge ---
var is_dodging     := false
var dodge_timer    := 0.0
var dodge_direction := 1.0

# --- Ataque (Espetão de Costela) ---
var is_attacking         := false
var attack_timer         := 0.0
const ATTACK_DURATION     = 0.35
const ATTACK_COOLDOWN     = 0.8
var can_attack           := true
var attack_cooldown_timer := 0.0
var espetao_damage       := 35

# --- Direção ---
var facing_right := true

# --- Sinais ---
signal health_changed(new_hp: int)
signal player_died

func _ready():
	add_to_group("player")

func _physics_process(delta: float):
	# Gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# ---- Esquiva (i-frames) ----
	if is_dodging:
		dodge_timer -= delta
		velocity.x = dodge_direction * DODGE_SPEED
		if dodge_timer <= 0:
			is_dodging = false
		move_and_slide()
		return

	# ---- Cooldowns ----
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false

	# ---- Pulo (simples + duplo) ----
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			can_double_jump = true
		elif can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false

	if is_on_floor():
		can_double_jump = true

	# ---- Movimento horizontal ----
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * SPEED
		facing_right = direction > 0
		$AttackArea.scale.x = 1 if facing_right else -1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.3)

	# ---- Esquiva ----
	if Input.is_action_just_pressed("dodge") and is_on_floor() and not is_dodging:
		is_dodging = true
		dodge_timer = DODGE_DURATION
		dodge_direction = 1.0 if facing_right else -1.0

	# ---- Ataque (Espetão de Costela) ----
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		_perform_attack()

	move_and_slide()

	# Morte por queda
	if global_position.y > 800:
		die()

func _perform_attack():
	is_attacking = true
	attack_timer = ATTACK_DURATION
	can_attack = false
	attack_cooldown_timer = ATTACK_COOLDOWN
	# Dano em todos os inimigos no alcance
	for body in $AttackArea.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			body.take_damage(espetao_damage)

func take_damage(amount: int):
	if is_dodging:
		return  # i-frames durante esquiva
	current_hp = max(current_hp - amount, 0)
	health_changed.emit(current_hp)
	# Efeito de flash vermelho
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	if current_hp <= 0:
		die()

func heal(amount: int):
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp)

func die():
	player_died.emit()
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

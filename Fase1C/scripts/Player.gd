extends CharacterBody2D

# --- Movimento ---
const SPEED          = 250.0
const JUMP_VELOCITY  = -420.0
const GRAVITY        = 900.0
const DODGE_SPEED    = 450.0
const DODGE_DURATION = 0.3
const DODGE_COOLDOWN = 3.0

# --- Vida ---
var max_hp     := 100
var current_hp := 100

# --- Double Jump ---
var can_double_jump := true

# --- Dodge ---
var is_dodging           := false
var dodge_timer          := 0.0
var dodge_direction      := 1.0
var can_dodge            := true
var dodge_cooldown_timer := 0.0

# --- Ataque ---
var is_attacking          := false
var attack_timer          := 0.0
const ATTACK_DURATION      = 0.35
const ATTACK_COOLDOWN      = 0.8
var can_attack            := true
var attack_cooldown_timer := 0.0
var espetao_damage        := 35

# --- Direção ---
var facing_right := true

signal health_changed(new_hp: int)
signal player_died

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# ---- Esquiva com efeito fantasma ----
	if is_dodging:
		dodge_timer -= delta
		velocity.x = dodge_direction * DODGE_SPEED
		# Efeito fantasma: semi-transparente azul-branco
		modulate = Color(0.4, 0.85, 1.0, 0.22)
		_update_dash_bar(dodge_timer / DODGE_DURATION, true)
		if dodge_timer <= 0:
			is_dodging = false
			can_dodge  = false
			dodge_cooldown_timer = DODGE_COOLDOWN
			# Volta ao normal suavemente
			var t = create_tween()
			t.tween_property(self, "modulate", Color.WHITE, 0.18)
		move_and_slide()
		return

	# ---- Cooldown do dash ----
	if not can_dodge:
		dodge_cooldown_timer -= delta
		var recharge = 1.0 - (dodge_cooldown_timer / DODGE_COOLDOWN)
		_update_dash_bar(recharge, false)
		if dodge_cooldown_timer <= 0:
			can_dodge = true
			$DashBar.visible = false
	else:
		$DashBar.visible = false

	# ---- Cooldown de ataque ----
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
			$AttackArea/AttackVisual.visible = false
			$Espetao.rotation_degrees = -40.0 if facing_right else 40.0

	# ---- Pulo ----
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
		$AttackArea.scale.x    = 1 if facing_right else -1
		$Espetao.scale.x       = 1 if facing_right else -1
		$AttackArea.position.x = 30 if facing_right else -30
		$Espetao.position.x    = 18 if facing_right else -18
		if not is_attacking:
			$Espetao.rotation_degrees = -40.0 if facing_right else 40.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.3)

	# ---- Esquiva ----
	if Input.is_action_just_pressed("dodge") and is_on_floor() and not is_dodging and can_dodge:
		is_dodging      = true
		dodge_timer     = DODGE_DURATION
		dodge_direction = 1.0 if facing_right else -1.0

	# ---- Ataque ----
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		_perform_attack()

	move_and_slide()

	if global_position.y > 680:
		die()

func _update_dash_bar(ratio: float, is_active: bool) -> void:
	$DashBar.visible = true
	var fill = $DashBar/Fill
	fill.scale.x = clamp(ratio, 0.0, 1.0)
	if is_active:
		# Azul-ciano durante o dash
		fill.color = Color(0.2, 0.9, 1.0, 1.0)
		$DashBar/Label.text = "DASH"
	else:
		# Cinza durante o recarregamento
		fill.color = Color(0.55, 0.55, 0.6, 0.9)
		$DashBar/Label.text = "..."

func _perform_attack() -> void:
	is_attacking          = true
	attack_timer          = ATTACK_DURATION
	can_attack            = false
	attack_cooldown_timer = ATTACK_COOLDOWN
	$Espetao.rotation_degrees = -10.0 if facing_right else 10.0
	$AttackArea/AttackVisual.visible = true
	for body in $AttackArea.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			body.take_damage(espetao_damage)

func take_damage(amount: int) -> void:
	if is_dodging:
		return
	current_hp = max(current_hp - amount, 0)
	health_changed.emit(current_hp)
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	if current_hp <= 0:
		die()

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp)

func die() -> void:
	player_died.emit()
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

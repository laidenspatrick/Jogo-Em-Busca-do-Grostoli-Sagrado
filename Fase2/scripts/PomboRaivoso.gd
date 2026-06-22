extends CharacterBody2D
## Pombo Raivoso — Fase 1
## aerial  (sweep_mode=false): patrulha em altitude, pisca e mergulha, volta voando
## sweeper (sweep_mode=true) : patrulha rente ao chão, pisca e dá rasante
##
## O contato só causa dano durante a janela ativa do ataque (mergulho/rasante).
## Acertar o pombo (com qualquer arma) cancela o ataque na hora — não há mais
## chance de o jogador "acertar e ainda assim ser atingido".

@export var sweep_mode: bool = false

const FLY_SPEED    = 110.0
const RETURN_SPEED = 160.0
const PATROL_SPEED = 80.0
const CHARGE_SPEED = 420.0
const DIVE_SPEED   = 310.0
const GRAVITY      = 600.0
const DETECT_RANGE = 380.0
const WINDUP_TIME  = 0.65   # tempo de aviso antes do ataque (mais legível)

const KILL_REWARD_HP := 8   # recompensa de vida ao derrotar o pombo

var hp     := 30
var damage := 12
var direction := 1.0
var start_position := Vector2.ZERO
var player: Node2D = null
var is_dead := false

# ── AÉREO ─────────────────────────────────────────────────────────────────────
enum AerialState { PATROL, WINDUP, DIVING, RETURNING }
var aerial_state : AerialState = AerialState.PATROL
var patrol_range  := 160.0
var dive_timer    := 2.0
var dive_cooldown := 3.0

# ── SWEEPER ───────────────────────────────────────────────────────────────────
enum SweepState { PATROL, WINDUP, CHARGE, RETURN }
var sweep_state : SweepState = SweepState.PATROL
var sweep_y           := 0.0
var patrol_limit      := 200.0
var charge_origin     := 0.0
var charge_dir        := 1.0
const CHARGE_DIST      = 500.0
var charge_cooldown   := 0.0
const CHARGE_COOLDOWN  = 2.8

# ── COMPARTILHADO ─────────────────────────────────────────────────────────────
var windup_timer := 0.0
var blink_t      := 0.0
var wing_flap_t  := 0.0
var has_hit_player_this_attack := false

func _ready() -> void:
	add_to_group("enemies")
	start_position = global_position
	charge_origin  = global_position.x

	collision_mask = 0  # não colide com plataformas
	$WarningIcon.visible = false

	if sweep_mode:
		sweep_y = start_position.y
		charge_cooldown = 1.5

	await get_tree().process_frame
	var pl = get_tree().get_nodes_in_group("player")
	if pl.size() > 0:
		player = pl[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var attacking_now = (aerial_state == AerialState.DIVING or sweep_state == SweepState.CHARGE)
	wing_flap_t += delta * (14.0 if attacking_now else 8.0)
	if has_node("Wing1"): $Wing1.position.y = sin(wing_flap_t) * 5.0
	if has_node("Wing2"): $Wing2.position.y = sin(wing_flap_t) * 5.0

	if sweep_mode:
		_process_sweeper(delta)
	else:
		_process_aerial(delta)

	# Contato com o jogador só dói durante a janela ativa do ataque,
	# e no máximo uma vez por investida (evita dano repetido por frame)
	if attacking_now and player and not has_hit_player_this_attack:
		for body in $HitBox.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage)
				has_hit_player_this_attack = true

# ── MODO AÉREO ────────────────────────────────────────────────────────────────
func _process_aerial(delta: float) -> void:
	match aerial_state:

		AerialState.PATROL:
			velocity.x = direction * FLY_SPEED
			velocity.y = 0.0
			if abs(global_position.x - start_position.x) > patrol_range:
				direction *= -1

			dive_timer -= delta
			if dive_timer <= 0 and player:
				dive_timer = dive_cooldown
				if global_position.distance_to(player.global_position) < DETECT_RANGE:
					_aerial_begin_windup()

		AerialState.WINDUP:
			velocity = Vector2.ZERO
			blink_t += delta
			modulate = Color(1.0, 0.2, 0.2, 1.0) if fmod(blink_t, 0.18) < 0.09 else Color.WHITE
			windup_timer -= delta
			if windup_timer <= 0:
				modulate = Color.WHITE
				_aerial_start_dive()

		AerialState.DIVING:
			velocity.y += GRAVITY * delta
			if global_position.y > start_position.y + 240:
				_aerial_cancel_attack()

		AerialState.RETURNING:
			var to_home = start_position - global_position
			if to_home.length() < 12.0:
				global_position = start_position
				velocity        = Vector2.ZERO
				aerial_state    = AerialState.PATROL
			else:
				velocity = to_home.normalized() * RETURN_SPEED

	move_and_slide()

func _aerial_begin_windup() -> void:
	aerial_state = AerialState.WINDUP
	windup_timer = WINDUP_TIME
	blink_t      = 0.0
	velocity     = Vector2.ZERO
	$WarningIcon.visible = true

func _aerial_start_dive() -> void:
	aerial_state = AerialState.DIVING
	has_hit_player_this_attack = false
	$WarningIcon.visible = false
	if player:
		velocity = (player.global_position - global_position).normalized() * DIVE_SPEED
	else:
		velocity = Vector2(direction * DIVE_SPEED, DIVE_SPEED * 0.5)

func _aerial_cancel_attack() -> void:
	# Usado tanto ao terminar o mergulho quanto ao ser interrompido por um golpe
	aerial_state = AerialState.RETURNING
	velocity = Vector2.ZERO

# ── MODO SWEEPER ──────────────────────────────────────────────────────────────
func _process_sweeper(delta: float) -> void:
	global_position.y = sweep_y

	match sweep_state:

		SweepState.PATROL:
			velocity.x = direction * PATROL_SPEED
			velocity.y = 0.0
			if abs(global_position.x - start_position.x) > patrol_limit:
				direction *= -1
			charge_cooldown -= delta
			if charge_cooldown <= 0:
				_sweep_begin_windup()

		SweepState.WINDUP:
			velocity = Vector2.ZERO
			blink_t += delta
			modulate = Color(1.0, 0.2, 0.2, 1.0) if fmod(blink_t, 0.18) < 0.09 else Color.WHITE
			windup_timer -= delta
			if windup_timer <= 0:
				modulate = Color.WHITE
				_sweep_begin_charge()

		SweepState.CHARGE:
			velocity.x = charge_dir * CHARGE_SPEED
			velocity.y = 0.0
			if abs(global_position.x - charge_origin) >= CHARGE_DIST:
				_sweep_cancel_attack()

		SweepState.RETURN:
			var diff = start_position.x - global_position.x
			if abs(diff) < 8.0:
				global_position.x = start_position.x
				velocity          = Vector2.ZERO
				charge_cooldown   = CHARGE_COOLDOWN
				sweep_state       = SweepState.PATROL
			else:
				velocity.x = sign(diff) * CHARGE_SPEED * 0.6
				velocity.y = 0.0

	move_and_slide()

func _sweep_begin_windup() -> void:
	sweep_state  = SweepState.WINDUP
	windup_timer = WINDUP_TIME
	blink_t      = 0.0
	velocity     = Vector2.ZERO
	charge_dir   = sign(player.global_position.x - global_position.x) if player else direction
	$WarningIcon.visible = true

func _sweep_begin_charge() -> void:
	sweep_state   = SweepState.CHARGE
	charge_origin = global_position.x
	direction     = charge_dir
	has_hit_player_this_attack = false
	$WarningIcon.visible = false

func _sweep_cancel_attack() -> void:
	sweep_state = SweepState.RETURN

# ── DANO ──────────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if is_dead:
		return

	hp -= amount

	# Acertar o pombo interrompe QUALQUER ataque em andamento na hora —
	# isso garante que um golpe bem cronometrado nunca seja "ignorado".
	if aerial_state == AerialState.WINDUP:
		aerial_state = AerialState.PATROL
		dive_timer   = 1.5
		$WarningIcon.visible = false
	elif aerial_state == AerialState.DIVING:
		_aerial_cancel_attack()

	if sweep_state == SweepState.WINDUP:
		sweep_state     = SweepState.PATROL
		charge_cooldown = 1.5
		$WarningIcon.visible = false
	elif sweep_state == SweepState.CHARGE:
		_sweep_cancel_attack()

	if hp <= 0:
		_die()
		return

	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func _die() -> void:
	is_dead = true
	$WarningIcon.visible = false
	# Recompensa o jogador por enfrentar o inimigo em vez de ignorá-lo
	if player and player.has_method("heal"):
		player.heal(KILL_REWARD_HP)
	var controllers = get_tree().get_nodes_in_group("level_controller")
	if controllers.size() > 0 and controllers[0].has_method("on_pombo_defeated"):
		controllers[0].on_pombo_defeated()
	queue_free()

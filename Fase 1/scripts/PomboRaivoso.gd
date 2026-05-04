extends CharacterBody2D
## Pombo Raivoso - Inimigo da Fase 1
##
## Dois modos:
##   aerial  (sweep_mode = false) — patrulha em altitude, mergulha no jogador
##   sweeper (sweep_mode = true)  — alterna entre patrulha lenta e rasantes rápidos no chão

@export var sweep_mode: bool = false

const FLY_SPEED      = 110.0
const PATROL_SPEED   = 80.0     # velocidade lenta de patrulha no chão
const CHARGE_SPEED   = 420.0    # velocidade do rasante
const DIVE_SPEED     = 310.0
const GRAVITY        = 600.0
const DETECT_RANGE   = 380.0

var hp        := 30
var direction := 1.0
var damage    := 12

# --- estado aéreo ---
var is_diving     := false
var dive_timer    := 2.0
var dive_cooldown := 3.0
var patrol_range  := 160.0
var start_position := Vector2.ZERO

# --- estado sweeper ---
enum SweepState { PATROL, WINDUP, CHARGE, RETURN }
var sweep_state    : SweepState = SweepState.PATROL
var sweep_y        := 0.0
var patrol_limit   := 200.0   # largura da patrulha lenta

var windup_timer   := 0.0     # pausa antes de cobrar
const WINDUP_TIME  = 0.55     # tempo parado piscando

var charge_origin  := 0.0     # X de onde partiu o rasante
var charge_dir     := 1.0     # direção do rasante
const CHARGE_DIST  = 500.0    # distância percorrida no rasante

var charge_cooldown_timer := 0.0
const CHARGE_COOLDOWN     = 2.8  # segundos entre rasantes

# --- animação ---
var wing_flap_t := 0.0
var blink_t     := 0.0

var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	start_position   = global_position
	charge_origin    = global_position.x
	if sweep_mode:
		sweep_y = start_position.y
		# Começa o primeiro rasante um pouco depois para dar tempo ao jogador
		charge_cooldown_timer = 1.5
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	wing_flap_t += delta * (14.0 if sweep_state == SweepState.CHARGE else 8.0)
	if has_node("Wing1"): $Wing1.position.y = sin(wing_flap_t) * 5.0
	if has_node("Wing2"): $Wing2.position.y = sin(wing_flap_t) * 5.0

	if sweep_mode:
		_process_sweeper(delta)
	else:
		_process_aerial(delta)

# ── MODO AÉREO ───────────────────────────────────────────────────────────────
func _process_aerial(delta: float) -> void:
	if is_diving:
		velocity.y += GRAVITY * delta
		move_and_slide()
		if is_on_floor() or global_position.y > start_position.y + 220:
			is_diving   = false
			velocity    = Vector2.ZERO
			global_position = start_position
		return

	velocity.x = direction * FLY_SPEED
	velocity.y = 0.0
	if abs(global_position.x - start_position.x) > patrol_range:
		direction *= -1

	dive_timer -= delta
	if dive_timer <= 0 and player:
		dive_timer = dive_cooldown
		if global_position.distance_to(player.global_position) < DETECT_RANGE:
			_start_dive()
	move_and_slide()

func _start_dive() -> void:
	if not player: return
	is_diving = true
	velocity  = (player.global_position - global_position).normalized() * DIVE_SPEED

# ── MODO SWEEPER ─────────────────────────────────────────────────────────────
func _process_sweeper(delta: float) -> void:
	global_position.y = sweep_y  # mantém altura fixa no chão

	match sweep_state:

		SweepState.PATROL:
			velocity.x = direction * PATROL_SPEED
			velocity.y = 0.0
			if abs(global_position.x - start_position.x) > patrol_limit:
				direction *= -1

			charge_cooldown_timer -= delta
			if charge_cooldown_timer <= 0:
				_begin_windup()

		SweepState.WINDUP:
			# Para, pisca, prepara o rasante
			velocity = Vector2.ZERO
			blink_t += delta
			modulate = Color(1.0, 0.3, 0.3, 1.0) if fmod(blink_t, 0.18) < 0.09 else Color.WHITE
			windup_timer -= delta
			if windup_timer <= 0:
				modulate = Color.WHITE
				_begin_charge()

		SweepState.CHARGE:
			# Rasante rápido na direção escolhida
			velocity.x = charge_dir * CHARGE_SPEED
			velocity.y = 0.0
			var traveled = abs(global_position.x - charge_origin)
			if traveled >= CHARGE_DIST:
				_begin_return()

		SweepState.RETURN:
			# Volta rapidamente para a posição inicial
			var diff = start_position.x - global_position.x
			if abs(diff) < 8.0:
				global_position.x        = start_position.x
				velocity                  = Vector2.ZERO
				charge_cooldown_timer     = CHARGE_COOLDOWN
				sweep_state               = SweepState.PATROL
			else:
				velocity.x = sign(diff) * CHARGE_SPEED * 0.6
				velocity.y = 0.0

	move_and_slide()

func _begin_windup() -> void:
	sweep_state   = SweepState.WINDUP
	windup_timer  = WINDUP_TIME
	blink_t       = 0.0
	velocity      = Vector2.ZERO
	# Escolhe direção do rasante em direção ao jogador se possível
	if player:
		charge_dir = sign(player.global_position.x - global_position.x)
	else:
		charge_dir = direction

func _begin_charge() -> void:
	sweep_state   = SweepState.CHARGE
	charge_origin = global_position.x
	direction     = charge_dir

func _begin_return() -> void:
	sweep_state = SweepState.RETURN

# ── DANO ─────────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	hp -= amount
	if sweep_state != SweepState.WINDUP:  # não cancela o piscar do windup
		modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		queue_free()

func _on_hit_box_body_entered(body_node: Node2D) -> void:
	if body_node.is_in_group("player"):
		body_node.take_damage(damage)

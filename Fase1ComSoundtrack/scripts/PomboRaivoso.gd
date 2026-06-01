extends CharacterBody2D
## Pombo Raivoso — Fase 1
## aerial  (sweep_mode=false): patrulha em altitude, pisca e mergulha, volta voando
## sweeper (sweep_mode=true) : patrulha rente ao chão, pisca e dá rasante

@export var sweep_mode: bool = false

const FLY_SPEED    = 110.0
const RETURN_SPEED = 160.0
const PATROL_SPEED = 80.0
const CHARGE_SPEED = 420.0
const DIVE_SPEED   = 310.0
const GRAVITY      = 600.0
const DETECT_RANGE = 380.0
const WINDUP_TIME  = 0.5

var hp     := 30
var damage := 12
var direction := 1.0
var start_position := Vector2.ZERO
var player: Node2D = null

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

func _ready() -> void:
	add_to_group("enemies")
	start_position = global_position
	charge_origin  = global_position.x

	# Pombos não devem colidir com plataformas — só o HitBox detecta o player
	collision_mask = 0

	if sweep_mode:
		sweep_y = start_position.y
		charge_cooldown = 1.5

	await get_tree().process_frame
	var pl = get_tree().get_nodes_in_group("player")
	if pl.size() > 0:
		player = pl[0]

func _physics_process(delta: float) -> void:
	# Batida de asa mais rápida durante ataques
	var is_attacking = (aerial_state == AerialState.DIVING or sweep_state == SweepState.CHARGE)
	wing_flap_t += delta * (14.0 if is_attacking else 8.0)
	if has_node("Wing1"): $Wing1.position.y = sin(wing_flap_t) * 5.0
	if has_node("Wing2"): $Wing2.position.y = sin(wing_flap_t) * 5.0

	if sweep_mode:
		_process_sweeper(delta)
	else:
		_process_aerial(delta)

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
			# Para e pisca vermelho igual ao sweeper
			velocity = Vector2.ZERO
			blink_t += delta
			modulate = Color(1.0, 0.2, 0.2, 1.0) if fmod(blink_t, 0.18) < 0.09 else Color.WHITE
			windup_timer -= delta
			if windup_timer <= 0:
				modulate = Color.WHITE
				_aerial_start_dive()

		AerialState.DIVING:
			# Mergulha com gravidade — atravessa plataformas (collision_mask=0)
			velocity.y += GRAVITY * delta
			if global_position.y > start_position.y + 240:
				aerial_state = AerialState.RETURNING
				velocity = Vector2.ZERO

		AerialState.RETURNING:
			# Voa de volta visivelmente para o ponto de patrulha
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

func _aerial_start_dive() -> void:
	aerial_state = AerialState.DIVING
	if player:
		velocity = (player.global_position - global_position).normalized() * DIVE_SPEED
	else:
		velocity = Vector2(direction * DIVE_SPEED, DIVE_SPEED * 0.5)

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
				sweep_state = SweepState.RETURN

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

func _sweep_begin_charge() -> void:
	sweep_state   = SweepState.CHARGE
	charge_origin = global_position.x
	direction     = charge_dir

# ── DANO ──────────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	hp -= amount
	# Interrompe windup se levou dano
	if aerial_state == AerialState.WINDUP:
		aerial_state = AerialState.PATROL
		dive_timer   = 1.5
	if sweep_state == SweepState.WINDUP:
		sweep_state     = SweepState.PATROL
		charge_cooldown = 1.5
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		queue_free()

func _on_hit_box_body_entered(body_node: Node2D) -> void:
	if body_node.is_in_group("player"):
		body_node.take_damage(damage)

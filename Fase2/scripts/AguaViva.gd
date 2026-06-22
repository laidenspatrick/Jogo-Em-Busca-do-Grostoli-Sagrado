extends CharacterBody2D
## Água Viva (Mãe d'Água) — Inimigo da Fase 2
## Flutua na água, pisca em vermelho ao avistar o jogador, ERGUE-SE para fora
## da água durante o aviso e libera um "Choque" elétrico em área —
## único padrão de ataque, mas agora alcança de fato o jogador nos piers.

const DETECT_RANGE   = 280.0
const WINDUP_TIME    = 0.6
const SHOCK_DURATION = 0.35
const COOLDOWN_TIME  = 2.5
const BOB_AMPLITUDE  = 8.0
const BOB_SPEED      = 2.0
const LUNGE_HEIGHT   = 120.0   # o quanto ela se ergue da água ao atacar
const DESCEND_TIME   = 0.4

var hp     := 25
var damage := 15

enum State { IDLE, WINDUP, SHOCK, COOLDOWN }
var state : State = State.IDLE

var base_position := Vector2.ZERO
var bob_t            := 0.0
var blink_t          := 0.0
var windup_timer     := 0.0
var shock_timer      := 0.0
var cooldown_timer   := 0.0
var shock_hit_player := false
var lunge_offset_y   := 0.0
var lunge_tween: Tween = null

var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	base_position = global_position
	collision_mask = 0  # flutua livremente, não colide com plataformas
	$ShockArea.monitoring = false
	$ShockRing.scale = Vector2.ZERO

	await get_tree().process_frame
	var pl = get_tree().get_nodes_in_group("player")
	if pl.size() > 0:
		player = pl[0]

func _physics_process(delta: float) -> void:
	bob_t += delta * BOB_SPEED
	var bob_offset = sin(bob_t) * BOB_AMPLITUDE
	global_position = base_position + Vector2(0, bob_offset + lunge_offset_y)

	match state:
		State.IDLE:
			if player and global_position.distance_to(player.global_position) < DETECT_RANGE:
				_begin_windup()

		State.WINDUP:
			blink_t += delta
			modulate = Color(1.0, 0.2, 0.2, 1.0) if fmod(blink_t, 0.18) < 0.09 else Color.WHITE
			windup_timer -= delta
			if windup_timer <= 0:
				_begin_shock()

		State.SHOCK:
			shock_timer -= delta
			var t = 1.0 - (shock_timer / SHOCK_DURATION)
			$ShockRing.scale = Vector2.ONE * lerp(0.2, 1.6, clamp(t, 0.0, 1.0))
			$ShockRing.modulate.a = lerp(0.75, 0.0, clamp(t, 0.0, 1.0))
			if not shock_hit_player:
				for body in $ShockArea.get_overlapping_bodies():
					if body.is_in_group("player") and body.has_method("take_damage"):
						body.take_damage(damage)
						shock_hit_player = true
			if shock_timer <= 0:
				_end_shock()

		State.COOLDOWN:
			cooldown_timer -= delta
			if cooldown_timer <= 0:
				state = State.IDLE

func _begin_windup() -> void:
	state        = State.WINDUP
	windup_timer = WINDUP_TIME
	blink_t      = 0.0
	# Ergue-se da água durante o aviso — é isso que a torna alcançável
	if lunge_tween:
		lunge_tween.kill()
	lunge_tween = create_tween()
	lunge_tween.tween_property(self, "lunge_offset_y", -LUNGE_HEIGHT, WINDUP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _begin_shock() -> void:
	state            = State.SHOCK
	shock_timer      = SHOCK_DURATION
	shock_hit_player = false
	modulate         = Color.WHITE
	$ShockArea.monitoring = true

func _end_shock() -> void:
	state          = State.COOLDOWN
	cooldown_timer = COOLDOWN_TIME
	$ShockArea.monitoring = false
	$ShockRing.scale = Vector2.ZERO
	_descend()

func _descend() -> void:
	if lunge_tween:
		lunge_tween.kill()
	lunge_tween = create_tween()
	lunge_tween.tween_property(self, "lunge_offset_y", 0.0, DESCEND_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func take_damage(amount: int) -> void:
	hp -= amount
	if state == State.WINDUP:
		state          = State.COOLDOWN
		cooldown_timer = 1.2
		_descend()
	modulate = Color(1.6, 0.4, 0.4, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		queue_free()

extends CanvasLayer
## HUD - Interface do jogo (compartilhada entre fases)

@onready var health_bar:   ProgressBar = $HealthBar
@onready var weapon_label: Label       = $WeaponLabel
@onready var hp_label:     Label       = $HPLabel

@onready var metal_label:   Label = $MetalLabel
@onready var madeira_label: Label = $MadeiraLabel
@onready var kill_label:    Label = $KillLabel
@onready var message_label: Label = $MessageLabel

var message_tween: Tween = null

func _ready() -> void:
	health_bar.max_value = 100
	health_bar.value     = 100
	update_weapon("Espetao de Costela")
	set_collectibles_visible(false)
	set_kill_counter_visible(false)
	message_label.modulate.a = 0.0

func update_health(new_hp: int) -> void:
	health_bar.value = new_hp
	hp_label.text    = str(new_hp) + " / 100"

func update_weapon(weapon_name: String) -> void:
	weapon_label.text = "Arma: " + weapon_name

func set_collectibles_visible(value: bool) -> void:
	metal_label.visible   = value
	madeira_label.visible = value

func update_metal(count: int, required: int) -> void:
	metal_label.text = "Metal: " + str(count) + " / " + str(required)

func update_madeira(count: int, required: int) -> void:
	madeira_label.text = "Madeira: " + str(count) + " / " + str(required)

func set_kill_counter_visible(value: bool) -> void:
	kill_label.visible = value

func update_kills(count: int, total: int) -> void:
	kill_label.text = "Pombos abatidos: " + str(count) + " / " + str(total)

func show_message(text: String, duration: float = 2.5) -> void:
	message_label.text = text
	if message_tween:
		message_tween.kill()
	message_label.modulate.a = 0.0
	message_tween = create_tween()
	message_tween.tween_property(message_label, "modulate:a", 1.0, 0.25)
	message_tween.tween_interval(duration)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)

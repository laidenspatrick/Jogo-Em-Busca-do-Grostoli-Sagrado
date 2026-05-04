extends CanvasLayer
## HUD - Interface do jogo

@onready var health_bar:   ProgressBar = $HealthBar
@onready var weapon_label: Label       = $WeaponLabel
@onready var hp_label:     Label       = $HPLabel

func _ready() -> void:
	health_bar.max_value = 100
	health_bar.value     = 100
	update_weapon("Espetao de Costela")

func update_health(new_hp: int) -> void:
	health_bar.value = new_hp
	hp_label.text    = str(new_hp) + " / 100"

func update_weapon(weapon_name: String) -> void:
	weapon_label.text = "Arma: " + weapon_name

extends CanvasLayer
## HUD - Interface do jogo
## Barra de vida, arma equipada, contador de itens

@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_label: Label = $WeaponLabel
@onready var hp_label: Label = $HPLabel

func _ready():
	health_bar.max_value = 100
	health_bar.value = 100
	update_weapon("Espetão de Costela")

func update_health(new_hp: int):
	health_bar.value = new_hp
	hp_label.text = str(new_hp) + " / 100"

func update_weapon(weapon_name: String):
	weapon_label.text = "Arma: " + weapon_name

extends Area2D
## Projétil do Estilingue de Pinhão
## Médio alcance, cadência alta — eficaz contra a Mãe d'Água à distância

var speed    := 600.0
var damage   := 15
var direction := Vector2.RIGHT
var lifetime := 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

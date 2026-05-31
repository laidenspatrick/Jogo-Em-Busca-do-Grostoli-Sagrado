extends Area2D

## Quantidade de dano que o vidro causa ao pisar
@export var dano_do_vidro: int = 15 

func _ready() -> void:
	# Conecta o sinal de colisão via código
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# O seu Player.gd já se adiciona ao grupo "player" no _ready()
	if body.is_in_group("player"):
		# Chama a função de dano que já existe no seu script do jogador
		if body.has_method("take_damage"):
			body.take_damage(dano_do_vidro)
			
			# Opcional: Se o vidro quebrar/sumir depois de dar dano, descomente a linha abaixo
			# queue_free()

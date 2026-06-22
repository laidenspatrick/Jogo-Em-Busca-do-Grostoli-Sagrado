extends AudioStreamPlayer

func _ready():
	stream = load("res://audio/soundtrack.mp3")
	bus = "Master"
	volume_db = -8
	play()

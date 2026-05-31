extends Node
## Autoload que configura o mapa de input programaticamente.
## Isso evita o formato verboso de eventos no project.godot.

func _ready():
	_setup_input_map()

func _setup_input_map():
	_add_action("move_left",  [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("jump",       [KEY_SPACE, KEY_W, KEY_UP])
	_add_action("dodge",      [KEY_SHIFT])
	_add_action("attack",     [KEY_J])
	_add_action("switch_weapon_left",  [KEY_Q])
	_add_action("switch_weapon_right", [KEY_E])

func _add_action(action_name: String, keys: Array):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var event = InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action_name, event)

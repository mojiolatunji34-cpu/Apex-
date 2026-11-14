extends CanvasLayer

var speed_label: Label
var status_label: Label
var car_ref: ApexCar

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	speed_label = Label.new()
	speed_label.position = Vector2(24, 20)
	speed_label.add_theme_font_size_override("font_size", 34)
	speed_label.add_theme_color_override("font_color", Color.WHITE)
	speed_label.text = "000 km/h"
	root.add_child(speed_label)

	status_label = Label.new()
	status_label.position = Vector2(26, 62)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.94, 1.0))
	status_label.text = "APEX RACING  |  TEST SESSION"
	root.add_child(status_label)

	var steering := HBoxContainer.new()
	steering.anchor_left = 0.0
	steering.anchor_top = 1.0
	steering.anchor_right = 0.0
	steering.anchor_bottom = 1.0
	steering.offset_left = 22
	steering.offset_top = -116
	steering.offset_right = 232
	steering.offset_bottom = -18
	steering.add_theme_constant_override("separation", 12)
	root.add_child(steering)
	_add_action_button(steering, "◀", "steer_left", Vector2(96, 88))
	_add_action_button(steering, "▶", "steer_right", Vector2(96, 88))

	var pedals := VBoxContainer.new()
	pedals.anchor_left = 1.0
	pedals.anchor_top = 1.0
	pedals.anchor_right = 1.0
	pedals.anchor_bottom = 1.0
	pedals.offset_left = -142
	pedals.offset_top = -218
	pedals.offset_right = -18
	pedals.offset_bottom = -18
	pedals.add_theme_constant_override("separation", 8)
	root.add_child(pedals)
	_add_action_button(pedals, "ACCEL", "accelerate", Vector2(118, 82))
	_add_action_button(pedals, "BRAKE", "brake", Vector2(118, 82))
	_add_action_button(pedals, "HANDBRAKE", "handbrake", Vector2(118, 42))

func _process(_delta: float) -> void:
	if is_instance_valid(car_ref) and is_instance_valid(speed_label):
		speed_label.text = "%03d km/h" % roundi(car_ref.get_speed_kmh())

func _add_action_button(parent: Container, caption: String, action: String, button_size: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = button_size
	button.add_theme_font_size_override("font_size", 19 if caption.length() < 7 else 13)
	button.focus_mode = Control.FOCUS_NONE
	button.modulate = Color(1, 1, 1, 0.9)
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	parent.add_child(button)

func _press_action(action: String) -> void:
	Input.action_press(action)

func _release_action(action: String) -> void:
	Input.action_release(action)

func _exit_tree() -> void:
	for action in ["steer_left", "steer_right", "accelerate", "brake", "reverse", "handbrake"]:
		Input.action_release(action)

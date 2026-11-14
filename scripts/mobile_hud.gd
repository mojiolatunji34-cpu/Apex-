extends CanvasLayer

var speed_label: Label
var gear_label: Label
var rpm_label: Label
var damage_label: Label
var lap_label: Label
var time_label: Label
var checkpoint_label: Label
var best_label: Label
var countdown_label: Label
var car_ref: ApexCar
var race_ref: Node
var pause_button: Button
var result_panel: PanelContainer
var result_label: Label
var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	speed_label = _make_label(root, Vector2(24, 18), 34, "000 km/h")
	gear_label = _make_label(root, Vector2(26, 166), 24, "GEAR 1")
	rpm_label = _make_label(root, Vector2(26, 194), 16, "RPM 0900")
	damage_label = _make_label(root, Vector2(26, 216), 15, "DAMAGE 00%")
	lap_label = _make_label(root, Vector2(26, 62), 20, "LAP 1 / 3")
	time_label = _make_label(root, Vector2(26, 90), 18, "00:00.000")
	checkpoint_label = _make_label(root, Vector2(26, 116), 14, "CHECKPOINT 1 / 4")
	best_label = _make_label(root, Vector2(26, 138), 14, "BEST --:--.---")
	countdown_label = _make_label(root, Vector2(0, 0), 58, "3")
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown_label.position = Vector2(-28, -58)
	countdown_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.18))

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
	pedals.offset_top = -300
	pedals.offset_right = -18
	pedals.offset_bottom = -18
	pedals.add_theme_constant_override("separation", 5)
	root.add_child(pedals)
	_add_action_button(pedals, "ACCEL", "accelerate", Vector2(118, 64))
	_add_action_button(pedals, "BRAKE", "brake", Vector2(118, 64))
	_add_action_button(pedals, "REVERSE", "reverse", Vector2(118, 42))
	_add_action_button(pedals, "HANDBRAKE", "handbrake", Vector2(118, 42))
	var reset_button := Button.new()
	reset_button.text = "RESET CAR"
	reset_button.custom_minimum_size = Vector2(118, 38)
	reset_button.pressed.connect(_reset_car)
	pedals.add_child(reset_button)

	pause_button = Button.new()
	pause_button.text = "PAUSE"
	pause_button.position = Vector2(-142, 18)
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.custom_minimum_size = Vector2(118, 44)
	pause_button.pressed.connect(_toggle_pause)
	root.add_child(pause_button)

	result_panel = PanelContainer.new()
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(-190, -95)
	result_panel.custom_minimum_size = Vector2(380, 190)
	result_panel.visible = false
	root.add_child(result_panel)
	var result_content := VBoxContainer.new()
	result_content.alignment = BoxContainer.ALIGNMENT_CENTER
	result_panel.add_child(result_content)
	result_label = Label.new()
	result_label.text = "RACE COMPLETE"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 28)
	result_content.add_child(result_label)
	var result_restart := Button.new()
	result_restart.text = "RACE AGAIN"
	result_restart.custom_minimum_size = Vector2(180, 52)
	result_restart.pressed.connect(_restart_race)
	result_content.add_child(result_restart)

func _process(_delta: float) -> void:
	if is_instance_valid(car_ref):
		speed_label.text = "%03d km/h" % roundi(car_ref.get_speed_kmh())
		gear_label.text = "GEAR " + car_ref.get_gear_text()
		rpm_label.text = "RPM %04d" % roundi(car_ref.get_rpm())
		damage_label.text = car_ref.get_damage_text()
		damage_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.22) if car_ref.damage_amount >= 35.0 else Color.WHITE)
	if is_instance_valid(race_ref):
		lap_label.text = race_ref.get_lap_text()
		time_label.text = race_ref.get_time_text()
		checkpoint_label.text = race_ref.get_checkpoint_text()
		best_label.text = race_ref.get_best_lap_text()
		countdown_label.text = race_ref.get_countdown_text()
		countdown_label.visible = not countdown_label.text.is_empty() and not race_ref.is_race_finished()
		if race_ref.is_race_finished():
			result_label.text = "RACE COMPLETE\nTIME  " + race_ref.get_time_text() + "\nBEST  " + race_ref.get_best_lap_text().replace("BEST ", "")
			result_panel.visible = true

func _make_label(parent: Control, point: Vector2, font_size: int, value: String) -> Label:
	var label := Label.new()
	label.position = point
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.text = value
	parent.add_child(label)
	return label

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

func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_button.text = "RESUME" if is_paused else "PAUSE"

func _restart_race() -> void:
	get_tree().paused = false
	is_paused = false
	pause_button.text = "PAUSE"
	result_panel.visible = false
	if is_instance_valid(race_ref):
		race_ref.restart_race()

func _reset_car() -> void:
	if is_instance_valid(car_ref):
		car_ref.reset_vehicle()

func _exit_tree() -> void:
	get_tree().paused = false
	for action in ["steer_left", "steer_right", "accelerate", "brake", "reverse", "handbrake"]:
		Input.action_release(action)

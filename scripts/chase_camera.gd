extends Camera3D

@export var follow_distance: float = 8.5
@export var follow_height: float = 4.2
@export var position_smoothing: float = 5.0
@export var look_height: float = 1.0

var target: Node3D

func _ready() -> void:
	current = true
	fov = 72.0
	near = 0.1
	far = 500.0

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var behind := target.global_transform.basis.z
	var desired := target.global_position + behind * follow_distance + Vector3.UP * follow_height
	global_position = global_position.lerp(desired, clampf(delta * position_smoothing, 0.0, 1.0))
	look_at(target.global_position + Vector3.UP * look_height, Vector3.UP)

extends Camera3D

@export var follow_distance: float = 8.5
@export var follow_height: float = 4.2
@export var position_smoothing: float = 5.0
@export var look_height: float = 1.0

var target: Node3D
var motion_phase: float = 0.0
var camera_roll: float = 0.0

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
	var car := target as ApexCar
	var speed_kmh := 0.0
	var look_ahead := Vector3.ZERO
	var speed_factor := 0.0
	var steer_factor := 0.0
	if car != null:
		speed_kmh = car.get_speed_kmh()
		speed_factor = clampf(speed_kmh / 180.0, 0.0, 1.0)
		steer_factor = car.smoothed_steer
		look_ahead = car.linear_velocity * 0.12

	# Keep the chase camera from clipping through nearby barriers or scenery.
	var query := PhysicsRayQueryParameters3D.create(
		target.global_position + Vector3.UP * look_height,
		desired
	)
	if car != null:
		query.exclude = [car.get_rid()]
	query.collision_mask = 1
	var obstruction := target.get_world_3d().direct_space_state.intersect_ray(query)
	if not obstruction.is_empty():
		desired = obstruction.position + obstruction.normal * 0.35

	# A restrained speed-linked camera motion adds feedback without making mobile play uncomfortable.
	motion_phase = fposmod(motion_phase + delta * lerpf(0.0, 10.5, speed_factor), TAU)
	var road_motion := sin(motion_phase) * 0.022 * speed_factor
	var corner_offset := -steer_factor * speed_factor * 0.10
	desired += Vector3.UP * road_motion + target.global_transform.basis.x * corner_offset
	global_position = global_position.lerp(desired, clampf(delta * position_smoothing, 0.0, 1.0))
	fov = lerpf(fov, 72.0 + speed_factor * 8.0, delta * 2.0)
	look_at(target.global_position + Vector3.UP * look_height + look_ahead, Vector3.UP)
	var target_roll := -steer_factor * speed_factor * 0.018
	camera_roll = lerpf(camera_roll, target_roll, clampf(delta * 3.5, 0.0, 1.0))
	rotation.z = camera_roll

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
	var car := target as ApexCar
	var speed_kmh := 0.0
	var look_ahead := Vector3.ZERO
	if car != null:
		speed_kmh = car.get_speed_kmh()
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

	global_position = global_position.lerp(desired, clampf(delta * position_smoothing, 0.0, 1.0))
	fov = lerpf(fov, 72.0 + clampf(speed_kmh / 210.0, 0.0, 1.0) * 8.0, delta * 2.0)
	look_at(target.global_position + Vector3.UP * look_height + look_ahead, Vector3.UP)

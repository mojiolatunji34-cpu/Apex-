extends RigidBody3D
class_name ApexCar

@export_group("Powertrain")
@export var engine_force: float = 9200.0
@export var reverse_force: float = 4300.0
@export var brake_force: float = 14500.0
@export var max_speed_kmh: float = 210.0

@export_group("Suspension and tyres")
@export var wheel_radius: float = 0.34
@export var suspension_rest_length: float = 0.55
@export var suspension_spring: float = 28000.0
@export var suspension_damper: float = 3600.0
@export var tyre_grip: float = 1.15
@export var handbrake_grip: float = 0.32
@export var max_steer_degrees: float = 30.0
@export var downforce: float = 38.0
@export var body_color: Color = Color(0.82, 0.045, 0.025)

@export_group("AI driver")
@export var ai_controlled: bool = false
@export var ai_cruise_speed_kmh: float = 82.0

var throttle_input: float = 0.0
var steer_input: float = 0.0
var brake_input: float = 0.0
var handbrake_input: float = 0.0
var wheel_visuals: Array[MeshInstance3D] = []
var suspension_rays: Array[RayCast3D] = []
var wheel_is_front: Array[bool] = []
var previous_compression: Array[float] = [0.0, 0.0, 0.0, 0.0]
var ai_waypoints: Array[Vector3] = []
var ai_target_index: int = 0
var spawn_transform: Transform3D

func _ready() -> void:
	mass = 1150.0
	linear_damp = 0.08
	angular_damp = 1.8
	continuous_cd = true
	can_sleep = false
	spawn_transform = global_transform
	_build_vehicle_visuals()

func _physics_process(delta: float) -> void:
	if ai_controlled:
		_update_ai_controls()
	else:
		_read_player_controls()

	var forward_speed := linear_velocity.dot(-global_transform.basis.z)
	var speed_kmh := linear_velocity.length() * 3.6
	var drive := throttle_input
	if drive > 0.0 and forward_speed * 3.6 >= max_speed_kmh:
		drive = 0.0
	if drive < 0.0 and forward_speed > 1.0:
		drive = 0.0
	if brake_input > 0.0:
		drive = 0.0

	var grounded_wheels := 0
	for i in range(suspension_rays.size()):
		var ray := suspension_rays[i]
		ray.force_raycast_update()
		var wheel := wheel_visuals[i]
		if not ray.is_colliding():
			previous_compression[i] = 0.0
			wheel.visible = false
			continue

		grounded_wheels += 1
		var hit_point: Vector3 = ray.get_collision_point()
		var hit_normal: Vector3 = ray.get_collision_normal().normalized()
		var travel_distance := ray.global_position.distance_to(hit_point)
		var compression := suspension_rest_length - (travel_distance - wheel_radius)
		var compression_velocity := (compression - previous_compression[i]) / maxf(delta, 0.0001)
		previous_compression[i] = compression

		var local_contact := to_local(hit_point)
		var point_velocity := get_velocity_at_local_position(local_contact)
		var suspension_force := maxf(0.0, compression * suspension_spring + compression_velocity * suspension_damper)
		apply_force(hit_normal * suspension_force, hit_point - global_position)

		var is_front := wheel_is_front[i]
		var steer_angle := -deg_to_rad(max_steer_degrees) * steer_input if is_front else 0.0
		var wheel_forward := (-global_transform.basis.z).rotated(hit_normal, steer_angle).normalized()
		var wheel_right := wheel_forward.cross(hit_normal).normalized()
		var side_speed := point_velocity.dot(wheel_right)
		var long_speed := point_velocity.dot(wheel_forward)
		var grip_scale := handbrake_grip if handbrake_input > 0.0 and not is_front else 1.0
		var max_tyre_force := suspension_force * tyre_grip
		var lateral_force := clampf(-side_speed * mass * 2.8 * grip_scale, -max_tyre_force, max_tyre_force)
		apply_force(wheel_right * lateral_force, hit_point - global_position)

		var longitudinal_force := 0.0
		if not is_front:
			longitudinal_force += drive * (engine_force if drive >= 0.0 else reverse_force) * 0.5
		if brake_input > 0.0:
			longitudinal_force += -signf(long_speed) * brake_force * brake_input * 0.25
		longitudinal_force = clampf(longitudinal_force, -max_tyre_force, max_tyre_force)
		apply_force(wheel_forward * longitudinal_force, hit_point - global_position)

		wheel.position = to_local(hit_point + hit_normal * wheel_radius)
		wheel.rotation.y = steer_angle
		wheel.visible = true
		wheel.rotate_object_local(Vector3.RIGHT, long_speed * delta / maxf(wheel_radius, 0.01))

	if speed_kmh > 8.0:
		apply_central_force(-global_transform.basis.y * speed_kmh * downforce)
	linear_damp = 0.18 if grounded_wheels == 0 else 0.08

func _read_player_controls() -> void:
	throttle_input = Input.get_action_strength("accelerate") - Input.get_action_strength("reverse")
	steer_input = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	brake_input = Input.get_action_strength("brake")
	handbrake_input = Input.get_action_strength("handbrake")

func _update_ai_controls() -> void:
	if ai_waypoints.is_empty():
		throttle_input = 0.0
		steer_input = 0.0
		brake_input = 1.0
		handbrake_input = 0.0
		return

	var target := ai_waypoints[ai_target_index]
	if global_position.distance_to(target) < 9.0:
		ai_target_index = (ai_target_index + 1) % ai_waypoints.size()
		target = ai_waypoints[ai_target_index]

	var local_target := global_transform.basis.inverse() * (target - global_position)
	var target_angle := atan2(local_target.x, maxf(-local_target.z, 0.1))
	steer_input = clampf(target_angle / 0.62, -1.0, 1.0)
	var corner_factor := clampf(1.0 - absf(target_angle) / 2.0, 0.38, 1.0)
	var target_speed := ai_cruise_speed_kmh * corner_factor
	var speed := get_speed_kmh()
	throttle_input = clampf((target_speed - speed) / 28.0, 0.0, 1.0)
	brake_input = clampf((speed - target_speed) / 22.0, 0.0, 1.0)
	handbrake_input = 0.0

func set_ai_route(points: Array[Vector3], cruise_speed: float = 82.0) -> void:
	ai_waypoints = points.duplicate()
	ai_cruise_speed_kmh = cruise_speed
	ai_target_index = 0

func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6

func reset_vehicle() -> void:
	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false
	for i in range(previous_compression.size()):
		previous_compression[i] = 0.0

func set_spawn_transform(value: Transform3D) -> void:
	spawn_transform = value

func _build_vehicle_visuals() -> void:
	var body_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.85, 0.58, 3.7)
	body_shape.shape = box_shape
	body_shape.position.y = 0.38
	add_child(body_shape)

	var body_mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.9, 0.54, 3.75)
	body_mesh.mesh = box_mesh
	body_mesh.position.y = 0.4
	var paint := StandardMaterial3D.new()
	paint.albedo_color = body_color
	paint.metallic = 0.72
	paint.roughness = 0.26
	body_mesh.material_override = paint
	add_child(body_mesh)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.38, 0.52, 1.65)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 0.88, 0.12)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.035, 0.09, 0.13)
	glass.metallic = 0.45
	glass.roughness = 0.16
	cabin.material_override = glass
	add_child(cabin)

	var wheel_material := StandardMaterial3D.new()
	wheel_material.albedo_color = Color(0.035, 0.035, 0.04)
	wheel_material.roughness = 0.88
	for x in [-0.98, 0.98]:
		for z in [-1.22, 1.22]:
			var ray := RayCast3D.new()
			ray.position = Vector3(x, 0.35, z)
			ray.target_position = Vector3(0, -(suspension_rest_length + wheel_radius + 0.45), 0)
			ray.enabled = true
			ray.collide_with_areas = false
			ray.collide_with_bodies = true
			add_child(ray)
			suspension_rays.append(ray)
			wheel_is_front.append(z < 0.0)

			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = wheel_radius
			wheel_mesh.bottom_radius = wheel_radius
			wheel_mesh.height = 0.24
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI / 2.0
			wheel.position = Vector3(x, -0.1, z)
			wheel.material_override = wheel_material
			add_child(wheel)
			wheel_visuals.append(wheel)

	var spoiler := MeshInstance3D.new()
	var spoiler_mesh := BoxMesh.new()
	spoiler_mesh.size = Vector3(1.65, 0.12, 0.32)
	spoiler.mesh = spoiler_mesh
	spoiler.position = Vector3(0, 0.88, 1.65)
	spoiler.material_override = paint
	add_child(spoiler)

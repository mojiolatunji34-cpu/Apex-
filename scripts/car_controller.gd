extends RigidBody3D
class_name ApexCar

@export var engine_force: float = 10500.0
@export var reverse_force: float = 5200.0
@export var brake_force: float = 12500.0
@export var steering_torque: float = 3900.0
@export var lateral_grip: float = 8.5
@export var max_speed_kmh: float = 190.0
@export var downforce: float = 32.0

var throttle_input: float = 0.0
var steer_input: float = 0.0
var brake_input: float = 0.0

func _ready() -> void:
	mass = 1150.0
	linear_damp = 0.08
	angular_damp = 2.8
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	continuous_cd = true
	can_sleep = false
	_build_vehicle_visuals()

func _physics_process(_delta: float) -> void:
	throttle_input = Input.get_action_strength("accelerate") - Input.get_action_strength("reverse")
	steer_input = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	brake_input = Input.get_action_strength("brake")

	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var forward_speed := linear_velocity.dot(forward)
	var speed_kmh := linear_velocity.length() * 3.6

	if throttle_input > 0.0 and speed_kmh < max_speed_kmh:
		apply_central_force(forward * throttle_input * engine_force)
	elif throttle_input < 0.0:
		if forward_speed > 1.0:
			apply_central_force(-forward * brake_force * absf(throttle_input))
		else:
			apply_central_force(forward * throttle_input * reverse_force)

	if brake_input > 0.0 and absf(forward_speed) > 0.2:
		apply_central_force(-forward * signf(forward_speed) * brake_force * brake_input)

	var sideways_speed := linear_velocity.dot(right)
	var grip_factor := clampf(1.0 - speed_kmh / 260.0, 0.35, 1.0)
	apply_central_force(-right * sideways_speed * lateral_grip * mass * grip_factor)

	var steering_factor := clampf(absf(forward_speed) / 5.0, 0.12, 1.0)
	var direction_factor := -1.0 if forward_speed < -0.5 else 1.0
	apply_torque(Vector3.UP * steer_input * steering_torque * steering_factor * direction_factor)

	if speed_kmh > 5.0:
		apply_central_force(-global_transform.basis.y * speed_kmh * downforce)

func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6

func _build_vehicle_visuals() -> void:
	var body_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.85, 0.62, 3.7)
	body_shape.shape = box_shape
	body_shape.position.y = 0.72
	add_child(body_shape)

	var body_mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.9, 0.58, 3.75)
	body_mesh.mesh = box_mesh
	body_mesh.position.y = 0.78
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.82, 0.045, 0.025)
	paint.metallic = 0.72
	paint.roughness = 0.26
	body_mesh.material_override = paint
	add_child(body_mesh)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.38, 0.52, 1.65)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 1.28, 0.12)
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
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.39
			wheel_mesh.bottom_radius = 0.39
			wheel_mesh.height = 0.24
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI / 2.0
			wheel.position = Vector3(x, 0.39, z)
			wheel.material_override = wheel_material
			add_child(wheel)

	var spoiler := MeshInstance3D.new()
	var spoiler_mesh := BoxMesh.new()
	spoiler_mesh.size = Vector3(1.65, 0.12, 0.32)
	spoiler.mesh = spoiler_mesh
	spoiler.position = Vector3(0, 1.25, 1.65)
	spoiler.material_override = paint
	add_child(spoiler)

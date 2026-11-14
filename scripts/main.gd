extends Node3D

const CarScript = preload("res://scripts/car_controller.gd")
const CameraScript = preload("res://scripts/chase_camera.gd")
const HudScript = preload("res://scripts/mobile_hud.gd")
const RaceScript = preload("res://scripts/race_manager.gd")

func _ready() -> void:
	_setup_input()
	_build_environment()
	_build_track()
	_add_track_markings()
	_spawn_player_car()
	_add_lighting()

func _setup_input() -> void:
	_add_key_action("accelerate", KEY_W)
	_add_key_action("accelerate", KEY_UP)
	_add_key_action("reverse", KEY_S)
	_add_key_action("reverse", KEY_DOWN)
	_add_key_action("brake", KEY_SPACE)
	_add_key_action("handbrake", KEY_SHIFT)
	_add_key_action("steer_left", KEY_A)
	_add_key_action("steer_left", KEY_LEFT)
	_add_key_action("steer_right", KEY_D)
	_add_key_action("steer_right", KEY_RIGHT)

func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)

func _build_environment() -> void:
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(150, 150)
	ground.mesh = ground_mesh
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.12, 0.31, 0.13)
	grass.roughness = 1.0
	ground.material_override = grass
	ground.position.y = -0.12
	add_child(ground)

	var ground_body := StaticBody3D.new()
	ground_body.position.y = -0.2
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(150, 0.3, 150)
	ground_collision.shape = ground_shape
	ground_body.add_child(ground_collision)
	add_child(ground_body)

func _build_track() -> void:
	_add_road(Vector3(0, 0, -32), Vector3(66, 0.08, 13))
	_add_road(Vector3(0, 0, 32), Vector3(66, 0.08, 13))
	_add_road(Vector3(-26.5, 0, 0), Vector3(13, 0.08, 77))
	_add_road(Vector3(26.5, 0, 0), Vector3(13, 0.08, 77))
	_add_barrier(Vector3(0, 0.65, -40), Vector3(70, 1.3, 0.7))
	_add_barrier(Vector3(0, 0.65, 40), Vector3(70, 1.3, 0.7))
	_add_barrier(Vector3(-33, 0.65, 0), Vector3(0.7, 1.3, 82))
	_add_barrier(Vector3(33, 0.65, 0), Vector3(0.7, 1.3, 82))
	_add_start_line()

func _add_start_line() -> void:
	for i in range(12):
		var tile := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.52, 0.025, 0.72)
		tile.mesh = mesh
		tile.position = Vector3(-2.86 + float(i) * 0.52, 0.055, 26.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.WHITE if i % 2 == 0 else Color(0.04, 0.04, 0.05)
		tile.material_override = material
		add_child(tile)

func _add_track_markings() -> void:
	# High-contrast edge stripes make the rectangular prototype circuit easier to read.
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.88, 0.89, 0.84)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.78, 0.045, 0.025)
	for side in [-1.0, 1.0]:
		for x in range(-28, 29, 4):
			_add_marking(Vector3(float(x), 0.065, side * 37.7), Vector3(3.0, 0.035, 0.34), red if posmod(x, 8) == 0 else white)
		for z in range(-36, 37, 4):
			_add_marking(Vector3(side * 32.2, 0.065, float(z)), Vector3(0.34, 0.035, 3.0), red if posmod(z, 8) == 0 else white)

func _add_marking(point: Vector3, dimensions: Vector3, material: Material) -> void:
	var marker := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	marker.mesh = mesh
	marker.position = point
	marker.material_override = material
	add_child(marker)

func _add_road(pos: Vector3, dimensions: Vector3) -> void:
	var road_body := StaticBody3D.new()
	road_body.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	road_body.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.105, 0.115, 0.13)
	asphalt.roughness = 0.94
	visual.material_override = asphalt
	road_body.add_child(visual)
	add_child(road_body)

func _add_barrier(pos: Vector3, dimensions: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	wall.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.82, 0.78)
	material.roughness = 0.8
	visual.material_override = material
	wall.add_child(visual)
	add_child(wall)

func _spawn_player_car() -> void:
	var car := CarScript.new()
	car.name = "PlayerCar"
	car.position = Vector3(26.5, 0.85, 21.0)
	add_child(car)
	car.set_spawn_transform(car.global_transform)

	var race := RaceScript.new()
	race.name = "RaceManager"
	add_child(race)
	race.set_player(car)

	var camera := CameraScript.new()
	camera.name = "ChaseCamera"
	camera.target = car
	camera.position = car.position + Vector3(0, 5, 9)
	add_child(camera)
	camera.current = true

	var ai_route: Array[Vector3] = [
		Vector3(26.5, 0.0, -30.0),
		Vector3(0.0, 0.0, -32.0),
		Vector3(-26.5, 0.0, -30.0),
		Vector3(-26.5, 0.0, 30.0),
		Vector3(0.0, 0.0, 32.0),
		Vector3(26.5, 0.0, 30.0)
	]
	var rival_one := _spawn_ai_car("Rival_01", Vector3(23.4, 0.85, 27.0), Color(0.025, 0.24, 0.82), ai_route, 76.0)
	var rival_two := _spawn_ai_car("Rival_02", Vector3(29.6, 0.85, 27.0), Color(0.95, 0.58, 0.025), ai_route, 72.0)
	race.set_rivals([rival_one, rival_two])

	var hud := HudScript.new()
	hud.name = "MobileHUD"
	hud.car_ref = car
	hud.race_ref = race
	add_child(hud)

func _spawn_ai_car(car_name: String, spawn_point: Vector3, paint_color: Color, route: Array[Vector3], cruise_speed: float) -> ApexCar:
	var rival := CarScript.new()
	rival.name = car_name
	rival.position = spawn_point
	rival.body_color = paint_color
	rival.ai_controlled = true
	add_child(rival)
	rival.set_spawn_transform(rival.global_transform)
	rival.set_ai_route(route, cruise_speed)
	return rival

func _add_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.72)
	environment.ambient_light_energy = 0.55
	world_environment.environment = environment
	add_child(world_environment)

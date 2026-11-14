extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_test")

func _run_smoke_test() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	if packed_scene == null:
		push_error("Smoke test failed: main scene could not be loaded")
		quit(1)
		return

	var game := packed_scene.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	await process_frame

	var player := game.get_node_or_null("PlayerCar") as ApexCar
	var race := game.get_node_or_null("RaceManager")
	var camera := game.get_node_or_null("ChaseCamera") as Camera3D
	var hud := game.get_node_or_null("MobileHUD")

	if player == null or race == null or camera == null or hud == null:
		push_error("Smoke test failed: one or more core gameplay nodes are missing")
		quit(1)
		return
	if not camera.current:
		push_error("Smoke test failed: chase camera is not current")
		quit(1)
		return
	if player.get_node_or_null("TyreSmoke") == null:
		push_error("Smoke test failed: tyre smoke effect was not created")
		quit(1)
		return
	if player.body_animation_nodes.size() < 5:
		push_error("Smoke test failed: animated body visual nodes were not registered")
		quit(1)
		return
	if player.wheel_steering_pivots.size() != 4 or player.wheel_visuals.size() != 4:
		push_error("Smoke test failed: four wheel steering pivots and wheel meshes were not created")
		quit(1)
		return
	if player.get_node_or_null("EngineAudio") == null:
		push_error("Smoke test failed: spatial engine audio player was not created")
		quit(1)
		return
	if player.reverse_light_material == null or player.brake_light_material == null:
		push_error("Smoke test failed: rear brake and reverse light materials were not created")
		quit(1)
		return
	if player.get_children().filter(func(node): return node is SpotLight3D and node.name.begins_with("HeadlightBeam_")).size() != 2:
		push_error("Smoke test failed: paired forward headlight beams were not created")
		quit(1)
		return
	player.register_collision_impact(22.0)
	if player.damage_amount <= 0.0 or player.get_engine_health_factor() >= 1.0:
		push_error("Smoke test failed: collision damage did not affect vehicle health")
		quit(1)
		return
	player.reset_vehicle()
	if player.damage_amount != 0.0:
		push_error("Smoke test failed: vehicle reset did not repair collision damage")
		quit(1)
		return
	if not is_equal_approx(player.get_steering_limit_degrees(0.0), player.max_steer_degrees):
		push_error("Smoke test failed: low-speed steering limit is incorrect")
		quit(1)
		return
	if player.get_steering_limit_degrees(180.0) >= player.max_steer_degrees:
		push_error("Smoke test failed: high-speed steering reduction is missing")
		quit(1)
		return
	if player.tyre_grip <= 0.0 or player.suspension_spring <= 0.0:
		push_error("Smoke test failed: tyre or suspension tuning is invalid")
		quit(1)
		return
	if player.get_gear_text() != "1" or player.get_rpm() <= 0.0:
		push_error("Smoke test failed: powertrain telemetry did not initialize")
		quit(1)
		return

	var rivals := [game.get_node_or_null("Rival_01"), game.get_node_or_null("Rival_02")]
	if rivals[0] == null or rivals[1] == null:
		push_error("Smoke test failed: AI rivals did not spawn")
		quit(1)
		return

	race.restart_race()
	if race.is_race_finished() or race.get_lap_text() != "LAP 1 / 3":
		push_error("Smoke test failed: race restart did not reset race state")
		quit(1)
		return

	# Run a short deterministic soak test after restart: the countdown must finish,
	# the race clock must advance, and every vehicle must retain finite transforms.
	for frame in range(240):
		await physics_frame
	if not race.race_started:
		push_error("Smoke test failed: race countdown did not complete during soak test")
		quit(1)
		return
	if race.race_time <= 0.0:
		push_error("Smoke test failed: race timer did not advance during soak test")
		quit(1)
		return
	for vehicle in [player, rivals[0], rivals[1]]:
		if not is_finite(vehicle.global_position.x) or not is_finite(vehicle.global_position.y) or not is_finite(vehicle.global_position.z):
			push_error("Smoke test failed: a vehicle produced a non-finite position during soak test")
			quit(1)
			return
		if not is_finite(vehicle.linear_velocity.length()):
			push_error("Smoke test failed: a vehicle produced a non-finite velocity during soak test")
			quit(1)
			return
		if absf(vehicle.steer_input) > 1.001 or vehicle.throttle_input < -1.001 or vehicle.throttle_input > 1.001:
			push_error("Smoke test failed: vehicle control output exceeded safe input bounds")
			quit(1)
			return

	# Release the generated 3D scene before exiting so the headless renderer can clean up its mesh resources.
	game.queue_free()
	await process_frame
	await process_frame
	print("APEX RACING SMOKE TEST PASSED")
	quit(0)

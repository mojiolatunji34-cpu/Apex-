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
	if player.get_node_or_null("EngineAudio") == null:
		push_error("Smoke test failed: spatial engine audio player was not created")
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

	print("APEX RACING SMOKE TEST PASSED")
	quit(0)

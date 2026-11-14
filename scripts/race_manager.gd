extends Node

signal race_updated(lap: int, checkpoint: int, elapsed: float, best_lap: float)

@export var total_laps: int = 3

var player: ApexCar
var current_lap: int = 1
var next_checkpoint: int = 0
var race_time: float = 0.0
var lap_start_time: float = 0.0
var best_lap_time: float = 0.0
var race_finished: bool = false
var checkpoint_areas: Array[Area3D] = []

func _ready() -> void:
	_create_checkpoint(0, Vector3(26.5, 1.0, -20.0), Vector3(10.0, 2.5, 1.5))
	_create_checkpoint(1, Vector3(-20.0, 1.0, -32.0), Vector3(1.5, 2.5, 10.0))
	_create_checkpoint(2, Vector3(-26.5, 1.0, 20.0), Vector3(10.0, 2.5, 1.5))
	_create_checkpoint(3, Vector3(20.0, 1.0, 32.0), Vector3(1.5, 2.5, 10.0))
	_create_finish_gate()

func _process(delta: float) -> void:
	if race_finished or not is_instance_valid(player):
		return
	race_time += delta
	race_updated.emit(current_lap, next_checkpoint, race_time, best_lap_time)

func set_player(value: ApexCar) -> void:
	player = value

func _create_checkpoint(index: int, point: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = "Checkpoint_%d" % (index + 1)
	area.position = point
	area.collision_layer = 0
	area.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_checkpoint_body_entered.bind(index))
	add_child(area)
	checkpoint_areas.append(area)

func _create_finish_gate() -> void:
	var area := Area3D.new()
	area.name = "FinishLine"
	area.position = Vector3(26.5, 1.0, 26.0)
	area.collision_layer = 0
	area.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(10.0, 2.5, 1.2)
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_finish_body_entered)
	add_child(area)

func _on_checkpoint_body_entered(body: Node3D, index: int) -> void:
	if body != player or race_finished or index != next_checkpoint:
		return
	next_checkpoint += 1
	race_updated.emit(current_lap, next_checkpoint, race_time, best_lap_time)

func _on_finish_body_entered(body: Node3D) -> void:
	if body != player or race_finished or next_checkpoint < 4:
		return
	var completed_lap := race_time - lap_start_time
	if best_lap_time <= 0.0 or completed_lap < best_lap_time:
		best_lap_time = completed_lap
	if current_lap >= total_laps:
		race_finished = true
	else:
		current_lap += 1
		next_checkpoint = 0
		lap_start_time = race_time
	race_updated.emit(current_lap, next_checkpoint, race_time, best_lap_time)

func get_lap_text() -> String:
	if race_finished:
		return "RACE COMPLETE"
	return "LAP %d / %d" % [current_lap, total_laps]

func get_checkpoint_text() -> String:
	if race_finished:
		return "FINISHED"
	return "CHECKPOINT %d / 4" % [next_checkpoint + 1]

func get_time_text() -> String:
	return _format_time(race_time)

func get_best_lap_text() -> String:
	if best_lap_time <= 0.0:
		return "BEST --:--.---"
	return "BEST " + _format_time(best_lap_time)

func _format_time(value: float) -> String:
	var minutes := int(value / 60.0)
	var seconds := int(fmod(value, 60.0))
	var milliseconds := int(fmod(value, 1.0) * 1000.0)
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

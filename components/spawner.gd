class_name GladiatorSpawner
extends Node2D

signal gladiator_spawned(gladiator: Node2D)
signal all_defeated

@export var gladiator_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 3.0
@export var max_alive: int = 20
@export var total_to_spawn: int = 0
@export var min_distance_from_player: float = 80.0
@export var max_distance_from_player: float = 500.0
@export var start_on_ready: bool = true
@export var spawn_parent: Node2D

var _alive: int = 0
var _spawned: int = 0
var _timer: Timer


func _ready() -> void:
	if spawn_parent == null:
		spawn_parent = get_parent().get_node_or_null("Props") as Node2D
	if spawn_parent == null:
		spawn_parent = get_parent() as Node2D

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	if start_on_ready:
		start()


func start() -> void:
	_timer.start()


func stop() -> void:
	_timer.stop()


func spawn_one() -> Node2D:
	if gladiator_scenes.is_empty():
		push_warning("GladiatorSpawner: no scenes assigned to gladiator_scenes.")
		return null

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return null

	var scene: PackedScene = gladiator_scenes[randi() % gladiator_scenes.size()]
	if scene == null:
		push_warning("GladiatorSpawner: an entry in gladiator_scenes is empty.")
		return null

	var gladiator := scene.instantiate() as Node2D
	if not (gladiator is Gladiator1 or gladiator is Gladiator2):
		push_warning("GladiatorSpawner: the scene's root must use the Gladiator1 or Gladiator2 script.")
		gladiator.queue_free()
		return null

	spawn_parent.add_child(gladiator)
	gladiator.global_position = _pick_spawn_position(player.global_position)

	_alive += 1
	_spawned += 1
	gladiator.tree_exited.connect(_on_gladiator_removed, CONNECT_ONE_SHOT)
	gladiator_spawned.emit(gladiator)
	return gladiator


func _on_timer_timeout() -> void:
	if total_to_spawn > 0 and _spawned >= total_to_spawn:
		_timer.stop()
		return
	if _alive >= max_alive:
		return
	spawn_one()


func _on_gladiator_removed() -> void:
	if not is_inside_tree():
		return
	_alive = maxi(_alive - 1, 0)
	if total_to_spawn > 0 and _spawned >= total_to_spawn and _alive <= 0:
		all_defeated.emit()


func _pick_spawn_position(player_pos: Vector2) -> Vector2:
	var angle := randf() * TAU
	var distance := randf_range(min_distance_from_player, max_distance_from_player)
	return player_pos + Vector2.from_angle(angle) * distance

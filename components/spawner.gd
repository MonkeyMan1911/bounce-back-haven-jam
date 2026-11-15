class_name GladiatorSpawner
extends Node2D
## Spawns gladiators at random arena doors on a timer.
## Add this as a child of the arena (or attach it to a Node2D), then drag your
## gladiator scene into "Gladiator Scene" in the Inspector.

signal gladiator_spawned(gladiator: Gladiator1)
signal all_defeated

@export var gladiator_scene: PackedScene
## Seconds between spawns.
@export var spawn_interval: float = 3.0
## Never have more than this many gladiators alive at once.
@export var max_alive: int = 5
## Stop after this many total spawns. 0 = spawn forever.
@export var total_to_spawn: int = 0
## Don't spawn a gladiator closer than this (pixels) to the player.
@export var min_distance_from_player: float = 80.0
@export var start_on_ready: bool = true

@export_group("Arena layout")
## Must match the arena (tiles).
@export var arena_width_tiles: int = 32
## Tile row where the arena floor starts (just below the arched doors).
@export var floor_start_row: int = 7
@export var tile_size: int = 16
## Where spawned gladiators are added. Leave empty to use the sibling node named "Props".
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


func spawn_one() -> Gladiator1:
if gladiator_scene == null:
push_warning("GladiatorSpawner: no gladiator_scene assigned.")
return null

var gladiator := gladiator_scene.instantiate() as Gladiator1
if gladiator == null:
push_warning("GladiatorSpawner: the scene's root must use the Gladiator1 script.")
return null

spawn_parent.add_child(gladiator)
gladiator.global_position = _pick_spawn_position()

_alive += 1
_spawned += 1
gladiator.tree_exited.connect(_on_gladiator_removed)
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
_alive -= 1
if total_to_spawn > 0 and _spawned >= total_to_spawn and _alive <= 0:
all_defeated.emit()


## Doors sit on every third tile of the north wall (x % 3 == 1), skipping the corners.
func _door_positions() -> Array[Vector2]:
var positions: Array[Vector2] = []
for x in range(2, arena_width_tiles - 2):
if x % 3 == 1:
var pos := Vector2(
x * tile_size + tile_size * 0.5,
(floor_start_row + 0.5) * tile_size
)
positions.append(to_global_from_arena(pos))
return positions


## Arena tile coordinates are relative to the arena root, so convert to world space.
func to_global_from_arena(local_pos: Vector2) -> Vector2:
var arena := get_parent() as Node2D
return arena.to_global(local_pos) if arena else local_pos


func _pick_spawn_position() -> Vector2:
var doors := _door_positions()
if doors.is_empty():
return global_position

var player := get_tree().get_first_node_in_group("player") as Node2D
var candidates: Array[Vector2] = []
for door in doors:
if player == null or door.distance_to(player.global_position) >= min_distance_from_player:
candidates.append(door)

# If every door is too close to the player, just use any door.
var chosen: Vector2 = candidates.pick_random() if not candidates.is_empty() else doors.pick_random()
# Small random offset so gladiators don't stack on the same pixel.
return chosen + Vector2(randf_range(-3.0, 3.0), randf_range(0.0, 4.0))

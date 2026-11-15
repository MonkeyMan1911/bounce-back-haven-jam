class_name Spear
extends Area2D

@export var speed: float = 160.0
@export var damage: float = 15.0
@export var max_range: float = 400.0
@export_flags_2d_physics var hit_mask: int = 1

var _direction: Vector2 = Vector2.DOWN
var _flying: bool = false
var _traveled: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = hit_mask
	monitoring = false
	body_entered.connect(_on_body_entered)


func aim(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle() + PI / 2.0


func launch(direction: Vector2) -> void:
	aim(direction)
	_flying = true
	set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	if not _flying:
		return
	var step := _direction * speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.health_component.update_health(damage)
		queue_free()

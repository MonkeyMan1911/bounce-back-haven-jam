class_name Bullet
extends Area2D

var speed: float
var damage: float
var bullet_range: float
var direction: Vector2
var distance_traveled: float = 0.0
var shooter: Node


func _ready() -> void:
	var gun := get_parent() as GunBase
	assert(gun != null, "Bullet must be spawned as a child of a GunBase")

	speed = gun.bullet_speed
	damage = gun.damage
	bullet_range = gun.bullet_range
	shooter = gun.get_parent()

	global_position = gun.shot_position
	direction = gun.shot_direction
	global_rotation = direction.angle()

	body_entered.connect(_on_body_entered)
	reparent.call_deferred(get_tree().current_scene)


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta

	global_position += movement
	distance_traveled += movement.length()

	if distance_traveled >= bullet_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()

class_name Bullet
extends Area2D

@export var max_bounces: int = -1

var speed: float
var damage: float
var bullet_range: float
var direction: Vector2
var distance_traveled: float = 0.0
var shooter: Node
var bounces: int = 0
var _exclude: Array[RID] = []


func _ready() -> void:
	add_to_group("bullets")

	var gun := get_parent() as GunBase
	assert(gun != null, "Bullet must be spawned as a child of a GunBase")

	speed = gun.bullet_speed
	damage = gun.damage
	bullet_range = gun.bullet_range
	shooter = gun.get_parent()

	global_position = gun.shot_position
	direction = gun.shot_direction
	global_rotation = direction.angle()

	_exclude.append(get_rid())
	if shooter is CollisionObject2D:
		_exclude.append(shooter.get_rid())

	reparent.call_deferred(get_tree().current_scene)


func _physics_process(delta: float) -> void:
	var remaining := speed * delta
	var space := get_world_2d().direct_space_state

	for i in 4:
		if remaining <= 0.0:
			break

		var query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + direction * remaining,
			collision_mask,
			_exclude
		)
		var hit := space.intersect_ray(query)

		if hit.is_empty():
			global_position += direction * remaining
			distance_traveled += remaining
			break

		var travelled := global_position.distance_to(hit.position)
		distance_traveled += travelled
		remaining -= travelled

		var collider = hit.collider
		if collider.has_method("take_damage"):
			collider.take_damage(damage)

		if max_bounces >= 0 and bounces >= max_bounces:
			queue_free()
			return

		bounces += 1
		direction = direction.bounce(hit.normal).normalized()
		global_position = hit.position + hit.normal * 0.1
		global_rotation = direction.angle()

	if distance_traveled >= bullet_range:
		queue_free()

class_name Gladiator1
extends CharacterBody2D

const SPEAR_SCENE := preload("res://entities/weapons/spear.tscn")

@export var speed: float = 60.0
@export var attack_damage: float = 10.0
@export_range(0.0, 1.0) var drop_chance: float = 0.5

@export_group("Spear")
@export var throw_windup: float = 0.4
@export var spear_regrow_time: float = 1.5
@export var spear_speed: float = 160.0
@export var hold_distance: float = 12.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var attack_radius_node: CollisionShape2D = $AttackRadius

var player: Player
var facing_direction: Vector2 = Vector2.DOWN

var spear_pivot: Marker2D
var held_spear: Spear

var _attack_range: float = 24.0
var _has_spear: bool = true
var _is_throwing: bool = false


func _ready() -> void:
	health_component.died.connect(die)

	attack_radius_node.set_deferred("disabled", true)
	var circle := attack_radius_node.shape as CircleShape2D
	if circle:
		_attack_range = circle.radius

	spear_pivot = Marker2D.new()
	spear_pivot.position = Vector2(0, 5)
	add_child(spear_pivot)

	held_spear = SPEAR_SCENE.instantiate() as Spear
	held_spear.position = Vector2(0, -hold_distance)
	spear_pivot.add_child(held_spear)
	_update_spear_pivot()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return

	if _is_throwing:
		velocity = Vector2.ZERO
		_update_sprite_animation("idle")
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	if to_player.length() > 0.01:
		facing_direction = to_player.normalized()

	var attack_center := global_position + attack_radius_node.position
	var in_range := attack_center.distance_to(player.global_position) <= _attack_range

	if in_range:
		velocity = Vector2.ZERO
		if _has_spear:
			_start_throw()
	else:
		velocity = facing_direction * speed

	_update_sprite_animation("walk" if velocity != Vector2.ZERO else "idle")
	_update_spear_pivot()
	move_and_slide()


func take_damage(attack_damage_amount) -> void:
	health_component.update_health(attack_damage_amount)


func die() -> void:
	if is_instance_valid(player):
		player.score += 20
	drop()
	queue_free()


func drop() -> void:
	if randf() > drop_chance:
		return
	var health_or_ammo = randi_range(1, 3)
	if health_or_ammo == 1:
		var ammo_drop := AmmoDrop.new()
		ammo_drop.position = position
		get_parent().add_child.call_deferred(ammo_drop)
	else:
		var health_drop := HealthDrop.new()
		health_drop.position = position
		get_parent().add_child.call_deferred(health_drop)


#  Spear
func _start_throw() -> void:
	_is_throwing = true
	_has_spear = false
	_update_spear_pivot()

	var tween := create_tween()
	tween.tween_interval(throw_windup)
	tween.tween_callback(_release_spear)


func _release_spear() -> void:
	var spear := SPEAR_SCENE.instantiate() as Spear
	spear.damage = attack_damage
	spear.speed = spear_speed

	get_parent().add_child(spear)
	spear.global_position = held_spear.global_position
	spear.launch(facing_direction)

	held_spear.visible = false
	_is_throwing = false
	get_tree().create_timer(spear_regrow_time).timeout.connect(_regrow_spear)


func _regrow_spear() -> void:
	_has_spear = true
	held_spear.visible = true


func _update_spear_pivot() -> void:
	spear_pivot.rotation = facing_direction.angle() + PI / 2.0


#  Animation
func _update_sprite_animation(state: String) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	var animation_name: String = state + "_" + _get_direction_string(facing_direction)
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)


func _get_direction_string(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"

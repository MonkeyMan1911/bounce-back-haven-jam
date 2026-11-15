class_name Gladiator2
extends CharacterBody2D

@export var speed: float = 40.0
@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 1.2
@export var swing_time: float = 0.25
@export var windup_time: float = 0.15
@export_range(30.0, 270.0) var swing_arc_degrees: float = 120.0

@export var attack_range_padding: float = 4.0
@export_range(0.0, 1.0) var drop_chance: float = 0.5

@onready var health_component: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var attack_radius_node: CollisionShape2D = $AttackRadius
@onready var axe_pivot: Marker2D = $AxePivot
@onready var axe: Area2D = $AxePivot/Axe

var player: Player
var facing_direction: Vector2 = Vector2.DOWN

var _attack_range: float = 24.0
var _swing_angle: float = 0.0
var _is_attacking: bool = false
var _can_attack: bool = true
var _hit_this_swing: bool = false


func _ready() -> void:
	health_component.died.connect(die)
	attack_radius_node.set_deferred("disabled", true)

	var circle := attack_radius_node.shape as CircleShape2D
	if circle:
		_attack_range = circle.radius

	axe.monitoring = false
	axe.body_entered.connect(_on_axe_body_entered)
	_update_axe_pivot()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return

	if _is_attacking:
		velocity = Vector2.ZERO
		_update_sprite_animation("idle")
		_update_axe_pivot()
		_check_swing_hits()
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var attack_center := global_position + attack_radius_node.position
	var in_range := attack_center.distance_to(player.global_position) <= _attack_range + attack_range_padding

	if to_player.length() > 0.01:
		facing_direction = to_player.normalized()

	if in_range:
		velocity = Vector2.ZERO
		if _can_attack:
			_start_attack()
	else:
		velocity = facing_direction * speed

	var is_walking := velocity != Vector2.ZERO
	_update_sprite_animation("walk" if is_walking else "idle")
	_update_axe_pivot()
	move_and_slide()


func take_damage(attack_damage_amount) -> void:
	health_component.update_health(attack_damage_amount)

func die() -> void:
	player.score += 30
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

#  Attacking
func _start_attack() -> void:
	_is_attacking = true
	_can_attack = false
	_hit_this_swing = false

	var half_arc := deg_to_rad(swing_arc_degrees) * 0.5
	_swing_angle = -half_arc

	var tween := create_tween()
	tween.tween_interval(windup_time)
	tween.tween_callback(func(): axe.monitoring = true)
	tween.tween_method(_set_swing_angle, -half_arc, half_arc, swing_time)
	tween.tween_callback(_end_swing)


func _set_swing_angle(value: float) -> void:
	_swing_angle = value


func _end_swing() -> void:
	axe.monitoring = false
	_swing_angle = 0.0
	_is_attacking = false
	_update_axe_pivot()
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): _can_attack = true)


func _on_axe_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _check_swing_hits() -> void:
	if not axe.monitoring or _hit_this_swing:
		return
	for body in axe.get_overlapping_bodies():
		_try_hit(body)


func _try_hit(body: Node2D) -> void:
	if not _is_attacking or _hit_this_swing:
		return
	if body is Player:
		_hit_this_swing = true  # one hit per swing
		body.health_component.update_health(attack_damage)

func _update_axe_pivot() -> void:
	axe_pivot.rotation = facing_direction.angle() - PI / 2.0 + _swing_angle


# Animation

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

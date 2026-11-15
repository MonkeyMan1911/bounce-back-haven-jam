class_name GunBase
extends CharacterBody2D

@onready var sprite: Sprite2D = $Pivot/Sprite
@onready var bullet_spawn: Marker2D = $Pivot/BulletSpawn

@export_group("Gun Stats")
@export var damage: float = 10.0
@export var fire_rate: float = 5.0 # Shots per second
@export var reload_speed: float = 1.5 # Seconds
@export var magazine_capacity: int = 12
@export var bullet_range: float = 500.0 # Pixels
@export var bullet_speed: float = 600.0 # Pixels per second (moved over from Bullet)
@export var bullet_scene: PackedScene


@export_group("Gun Appearance")
@export var gun_texture: Texture2D:
	set(value):
		gun_texture = value
		if is_node_ready():
			sprite.texture = gun_texture

var current_ammo: int
var can_fire: bool = true
var is_reloading: bool = false


func _ready() -> void:
	current_ammo = magazine_capacity
	if gun_texture:
		sprite.texture = gun_texture


func fire() -> void:
	if not can_fire or is_reloading or current_ammo <= 0:
		return

	can_fire = false
	current_ammo -= 1

	_on_fire()

	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_fire = true


func reload() -> void:
	if is_reloading or current_ammo == magazine_capacity:
		return

	is_reloading = true

	await get_tree().create_timer(reload_speed).timeout

	var parent = get_parent()
	if parent is Player:
		var reload_amount =  magazine_capacity - current_ammo
		if reload_amount > parent.ammo_pool:
			reload_amount = parent.ammo_pool

		parent.ammo_pool -= reload_amount
		current_ammo += reload_amount


	is_reloading = false


var shot_position: Vector2
var shot_direction: Vector2

func _on_fire() -> void:
	# Runs on the owning player's machine only (the input check happens there).
	_request_bullet.rpc_id(1, bullet_spawn.global_position, Vector2.DOWN.rotated(global_rotation))


# Owner -> server
@rpc("any_peer", "call_local", "reliable")
func _request_bullet(pos: Vector2, dir: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return   # someone is trying to fire another player's gun
	_spawn_bullet.rpc(pos, dir)   # server -> everyone, including itself


# Server -> everyone
@rpc("any_peer", "call_local", "reliable")
func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return   # only the server may spawn bullets
	shot_position = pos
	shot_direction = dir
	add_child(bullet_scene.instantiate())

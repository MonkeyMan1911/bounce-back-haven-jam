class_name Player
extends CharacterBody2D

const MAIN_MENU_SCENE := preload("res://components/main_menu.tscn")
const RESPAWN_MENU_SCENE := preload("res://components/respawn_menu.tscn")

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var gun: GunBase = $Gun
@onready var health_component: HealthComponent = $HealthComponent
@onready var camera: Camera2D = $Camera2D
@onready var hud: HUD = $HUD

@export var speed: float = 100.0
@export var acceleration: float = 100.0
@export var aim_deadzone: float = 6.0
@export var ammo_pool: int = 36

@export var max_respawns: int = 3
@export var respawn_delay: float = 3.0

var input_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.DOWN
var facing_direction: Vector2 = Vector2.DOWN
var gun_dir: float = 0.0

var bullets_paused: bool = false
var normal_bullet_speed: float

var score: int = 0
var respawns_left: int = 0


func _ready() -> void:
	add_to_group("player")
	respawns_left = max_respawns
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if score % 250 == 0 and score > 0:
		if health_component.current_health <= 60:
			health_component.current_health += 40
		ammo_pool += 25

	if score % 150 == 0 and score > 0:
		gun.bullet_range += 50
		gun.damage += 10

	if Input.is_action_just_pressed("time_pause"):
		if !bullets_paused:
			normal_bullet_speed = gun.bullet_speed
			gun.bullet_speed = 4
			bullets_paused = true
		else:
			_end_time_slow()

	if Input.is_action_pressed("shoot"):
		gun.fire()
	if Input.is_action_just_pressed("reload") or gun.current_ammo == 0:
		gun.reload()

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > aim_deadzone:
		aim_vector = to_mouse.normalized()

	gun_dir = wrapf(aim_vector.angle() - PI / 2.0, -PI, PI)
	gun.rotation = gun_dir
	_match_gun_sprite_direction()

	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_walking := input_vector != Vector2.ZERO

	if is_walking:
		var forward := aim_vector
		var right := aim_vector.rotated(PI / 2.0)
		var move_dir := forward * -input_vector.y + right * input_vector.x
		velocity = velocity.move_toward(move_dir * speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)

	_update_sprite_animation("walk" if is_walking else "idle")
	move_and_slide()


func take_damage(attack_damage):
	health_component.update_health(attack_damage)


# ---------- Death / respawn ----------

func _on_died() -> void:
	visible = false
	set_physics_process(false)
	_end_time_slow()

	if respawns_left > 0:
		respawns_left -= 1
		await _show_respawn_countdown()
		if not is_inside_tree():
			return
		_place_at_spawn()
	else:
		await _game_over()
		if not is_inside_tree():
			return
		score = 0
		respawns_left = max_respawns
		_place_at_spawn()

func _show_respawn_countdown() -> void:
	var menu = RESPAWN_MENU_SCENE.instantiate() as RespawnMenu
	menu.duration = respawn_delay
	get_tree().current_scene.add_child(menu)
	await menu.finished

func _game_over() -> void:
	MainMenu.save_high_score(score)
	var menu := MAIN_MENU_SCENE.instantiate() as MainMenu
	get_tree().current_scene.add_child(menu)
	await menu.new_game_pressed


func _place_at_spawn() -> void:
	global_position = get_parent().get_node("PlayerSpawn").global_position
	visible = true
	set_physics_process(true)
	health_component.current_health = 100
	_update_sprite_animation("idle")


func _end_time_slow() -> void:
	if not bullets_paused:
		return
	gun.bullet_speed = normal_bullet_speed
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.speed = normal_bullet_speed
	bullets_paused = false


# ---------- Facing ----------

func _quadrant_for_angle(angle: float) -> Vector2:
	if angle > -PI / 4.0 and angle < PI / 4.0:
		return Vector2.DOWN
	elif angle >= PI / 4.0 and angle <= 3.0 * PI / 4.0:
		return Vector2.LEFT
	elif angle > 3.0 * PI / 4.0 or angle < -3.0 * PI / 4.0:
		return Vector2.UP
	else:
		return Vector2.RIGHT


func _match_gun_sprite_direction() -> void:
	facing_direction = _quadrant_for_angle(gun_dir)


# ---------- Animation ----------

func _update_sprite_animation(state: String) -> void:
	if not animated_sprite:
		return
	var animation_name: String = state + "_" + _get_direction_string(facing_direction)
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)


func _get_direction_string(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"


func add_ammo(amt: int) -> void:
	ammo_pool += amt

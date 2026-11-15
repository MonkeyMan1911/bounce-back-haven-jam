class_name Player
extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var gun: GunBase = $Gun
@onready var health_component: HealthComponent = $HealthComponent
@onready var camera: Camera2D = $Camera2D
@onready var hud: HUD = $HUD   # change the type to match your HUD scene's root

@export var speed: float = 100.0
@export var acceleration: float = 100.0
@export var aim_deadzone: float = 6.0
@export var ammo_pool: int = 36

var input_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.DOWN
var facing_direction: Vector2 = Vector2.DOWN
var gun_dir: float = 0.0

var bullets_paused: bool = false
var normal_bullet_speed: float

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("time_pause"):
		if !bullets_paused:
			normal_bullet_speed = gun.bullet_speed
			gun.bullet_speed = 4
			bullets_paused = true
		else:
			gun.bullet_speed = normal_bullet_speed
			for bullet in get_tree().get_nodes_in_group("bullets"):
				bullet.speed = normal_bullet_speed
			bullets_paused = false

	if Input.is_action_pressed("shoot"):
		gun.fire()
		print(gun.current_ammo)
	if Input.is_action_just_pressed("reload") or gun.current_ammo == 0:
		gun.reload()

	# --- Aim: gun and sprite follow the cursor freely ---
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > aim_deadzone:
		aim_vector = to_mouse.normalized()

	# Gun angle (0 = down), wrapped to [-PI, PI]
	gun_dir = wrapf(aim_vector.angle() - PI / 2.0, -PI, PI)
	gun.rotation = gun_dir
	_match_gun_sprite_direction()

	# --- Movement relative to the aim direction ---
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_walking := input_vector != Vector2.ZERO

	if is_walking:
		var forward := aim_vector
		var right := aim_vector.rotated(PI / 2.0)   # perpendicular, to the player's right
		# get_vector's y is negative for "up", so flip it to get forward/back
		var move_dir := forward * -input_vector.y + right * input_vector.x
		velocity = velocity.move_toward(move_dir * speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)

	_update_sprite_animation("walk" if is_walking else "idle")
	move_and_slide()


func take_damage(attack_damage):
	health_component.update_health(attack_damage)

func respawn() -> void:
	visible = false
	set_physics_process(false)

	await get_tree().create_timer(3.0).timeout

	if not is_inside_tree():
		return

	var spawn_number = randi_range(1, 5)
	global_position = get_parent().get_node("Spawners/PlayerSpawn" + str(spawn_number)).global_position
	health_component.current_health = health_component.max_health
	velocity = Vector2.ZERO

	visible = true
	set_physics_process(true)
	_update_sprite_animation("idle")


# --- Facing ---

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


# --- Animation ---

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

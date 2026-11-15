class_name AmmoDrop
extends Area2D

@export var ammo_amount: int = 10
@export var pickup_radius: float = 8.0
@export var texture: Texture2D = preload("res://assets/UI/ammo-pistol.png")
@export_flags_2d_physics var detect_mask: int = 1


func _ready() -> void:
	collision_layer = 0
	collision_mask = detect_mask

	if not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = pickup_radius
		shape.shape = circle
		add_child(shape)

	if not _has_sprite():
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(0.5, 0.5)
		add_child(sprite)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func _has_sprite() -> bool:
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("add_ammo"):
			body.add_ammo(ammo_amount)
		queue_free()

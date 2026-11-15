class_name HealthComponent
extends Node

@export var health_bar: HealthBar
@export var max_health: float = 100.0
@export var current_health: float = 100.0

signal health_changed(current_health: float, max_health: float)
signal died

func set_max_health(amount: float) -> void:
	max_health = amount
	current_health = max_health
	health_changed.emit(current_health, max_health)

func update_health(amount: float) -> void: # Positive amt -> damage | Negative amt -> heal
	if current_health <= 0:
		return

	current_health = clamp(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		died.emit()

	if health_bar:
		health_bar.update_health(current_health, max_health)

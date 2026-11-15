class_name Dummy
extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent

func take_damage(attack_damage):
	health_component.update_health(attack_damage)

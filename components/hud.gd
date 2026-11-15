class_name HUD
extends CanvasLayer

@onready var ammo_label: Label = $Ammo/AmmoLabel
@onready var ammo_pool_label: Label = $Ammo/AmmoPoolLabel
@onready var health_bar: HealthBar = $Health/HealthBar

@export var player: Player

func _process(delta: float) -> void:
	# Ammo labels
	var gun = player.gun
	var ammo_label_text := ""
	ammo_label_text = str(gun.current_ammo) + "/" + str(gun.magazine_capacity)
	ammo_label.text = ammo_label_text
	ammo_pool_label.text = str(player.ammo_pool)

	#Health Bar
	health_bar.update_health(player.health_component.current_health, player.health_component.max_health)

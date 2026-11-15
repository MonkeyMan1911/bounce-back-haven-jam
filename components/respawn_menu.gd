class_name RespawnMenu
extends CanvasLayer

signal finished

var duration: float = 3.0

@onready var label: Label = $Label

var _time_left: float = 0.0
var _last_shown: int = -1


func _ready() -> void:
	_time_left = duration
	_update_label()


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		finished.emit()
		queue_free()
		return
	_update_label()


func _update_label() -> void:
	var seconds := ceili(_time_left)
	if seconds == _last_shown:
		return
	_last_shown = seconds
	label.text = "Respawn in: %d" % seconds

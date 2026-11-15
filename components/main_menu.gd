class_name MainMenu
extends CanvasLayer

signal new_game_pressed

const SAVE_PATH := "user://highscore.cfg"

@onready var score_label: Label = $Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	score_label.text = "High Score: %d" % load_high_score()
	get_tree().paused = true


func _on_button_button_down() -> void:
	new_game_pressed.emit()
	get_tree().paused = false
	queue_free()


static func load_high_score() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return cfg.get_value("scores", "high_score", 0)


static func save_high_score(score: int) -> void:
	if score <= load_high_score():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "high_score", score)
	cfg.save(SAVE_PATH)

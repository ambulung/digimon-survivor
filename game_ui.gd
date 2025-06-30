# File: game_ui.gd
extends CanvasLayer

# Make sure these node names match your scene tree exactly
@onready var xp_bar: ProgressBar = $XpBar
@onready var level_label: Label = $LevelLabel

# Called when the player's XP changes
func on_player_xp_changed(current_xp: float, xp_to_next_level: float) -> void:
	if xp_bar == null:
		push_warning("XpBar node not found or not yet initialized.")
		return
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp

# Called when the player's level changes
func on_player_level_changed(new_level: int) -> void:
	if level_label == null:
		push_warning("LevelLabel node not found or not yet initialized.")
		return
	level_label.text = "Level: " + str(new_level)

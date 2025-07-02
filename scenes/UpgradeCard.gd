# File: UpgradeCard.gd
extends PanelContainer

# This signal now emits the entire Dictionary choice data
signal upgrade_selected(choice_data: Dictionary)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var icon_rect: TextureRect = $VBoxContainer/Icon
@onready var button: Button = $Button

var current_choice_data: Dictionary

func _ready():
	button.pressed.connect(_on_button_pressed)

#
# --- THIS FUNCTION IS THE FIX ---
#
# It now accepts a Dictionary instead of a simple resource.
#
func display_upgrade(choice_data: Dictionary):
	current_choice_data = choice_data
	
	# Unpack the dictionary to get the data we need
	var weapon_data: WeaponUpgrade = choice_data["data"]
	var level: int = choice_data["level"]
	
	# The description for acquiring (Level 1) is at index 0.
	# The description for the first upgrade (Level 2) is at index 1, and so on.
	var description_index = level - 1
	
	# Set the UI elements from the unpacked data
	name_label.text = weapon_data.name
	description_label.text = weapon_data.levels[description_index].description
	
	if weapon_data.icon:
		icon_rect.texture = weapon_data.icon
		icon_rect.show()
	else:
		icon_rect.hide()

func _on_button_pressed():
	if not current_choice_data.is_empty():
		# When the card is clicked, emit the entire dictionary back up to the LevelUpUI
		emit_signal("upgrade_selected", current_choice_data)

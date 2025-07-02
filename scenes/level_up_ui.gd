# File: level_up_ui.gd
extends CanvasLayer

signal upgrade_chosen(choice_data: Dictionary) # The signal will also pass the dictionary

@export var upgrade_card_scene: PackedScene
@onready var card_container: HBoxContainer = $CenterContainer/CardContainer

#
# --- THIS FUNCTION IS THE FIX ---
#
# It now correctly expects an Array where each element is a Dictionary.
# I've removed the old type hint 'Array[Upgrade]' and just used 'Array'.
#
func present_choices(choices: Array):
	# Clear any old cards that might exist
	for child in card_container.get_children():
		child.queue_free()

	# Create a new card for each choice dictionary
	for choice_data in choices:
		var card = upgrade_card_scene.instantiate()
		card_container.add_child(card)
		
		# Pass the entire choice dictionary to the card
		card.display_upgrade(choice_data)
		
		# Listen for when this specific card is selected
		card.upgrade_selected.connect(_on_upgrade_selected)
		
# This function is called when any of the cards' "upgrade_selected" signal is emitted.
# It now correctly expects to receive the full choice_data dictionary back.
func _on_upgrade_selected(choice_data: Dictionary):
	# Broadcast a signal with the chosen upgrade data
	emit_signal("upgrade_chosen", choice_data)
	
	# The game is paused, so unpause it and remove the UI
	get_tree().paused = false
	queue_free()

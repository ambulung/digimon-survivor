extends CanvasLayer

signal upgrade_chosen

@export var upgrade_card_scene: PackedScene
@onready var card_container: HBoxContainer = $CenterContainer/CardContainer

# This function is called from the player script.
# It receives the upgrade choices and creates the cards.
func present_choices(upgrades: Array[Upgrade]):
	# Clear any old cards that might exist
	for child in card_container.get_children():
		child.queue_free()

	# Create a new card for each choice
	for upgrade in upgrades:
		var card = upgrade_card_scene.instantiate()
		card_container.add_child(card)
		card.display_upgrade(upgrade)
		# Listen for when this specific card is selected
		card.upgrade_selected.connect(_on_upgrade_selected)
		
# This function is called when any of the cards' "upgrade_selected" signal is emitted.
func _on_upgrade_selected(upgrade: Upgrade):
	# Broadcast a signal with the chosen upgrade data
	emit_signal("upgrade_chosen", upgrade)
	
	# The game is paused, so unpause it and remove the UI
	get_tree().paused = false
	queue_free()

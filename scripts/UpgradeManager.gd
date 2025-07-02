extends Node

# Change this to hold our new WeaponUpgrade resources
@export var weapon_upgrade_pool: Array[WeaponUpgrade]

# This function is now much smarter
func get_upgrade_choices(player_inventory: Dictionary, count: int) -> Array[Dictionary]:
	var possible_choices: Array[Dictionary] = []

	# Loop through all weapons available in the game
	for weapon_data in weapon_upgrade_pool:
		var weapon_id = weapon_data.id

		if not player_inventory.has(weapon_id):
			# --- Case 1: Player does NOT have this weapon ---
			# Offer to acquire it (Level 1, which is index 0 in our array)
			possible_choices.append({
				"data": weapon_data,
				"level": 1 
			})
		else:
			# --- Case 2: Player OWNS this weapon ---
			var current_level = player_inventory[weapon_id]
			# Check if the weapon is not at max level
			if current_level < weapon_data.levels.size():
				# Offer the next level upgrade
				possible_choices.append({
					"data": weapon_data,
					"level": current_level + 1
				})

	# Shuffle the valid choices and pick the requested number
	possible_choices.shuffle()
	
	var final_choices: Array[Dictionary] = []
	var num_to_pick = min(count, possible_choices.size())
	for i in range(num_to_pick):
		final_choices.append(possible_choices[i])
		
	return final_choices

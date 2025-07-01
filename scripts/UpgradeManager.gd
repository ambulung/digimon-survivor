extends Node

# We will drag all our created Upgrade resources into this array in the Inspector.
@export var upgrade_pool: Array[Upgrade]

# This function will be called by the player to get 3 random, unique choices.
func get_random_upgrades(count: int) -> Array[Upgrade]:
	var choices: Array[Upgrade] = []
	if upgrade_pool.size() < count:
		push_warning("Not enough upgrades in the pool to choose from!")
		return upgrade_pool

	# Create a temporary shuffled copy of the pool to draw from
	var temp_pool = upgrade_pool.duplicate()
	temp_pool.shuffle()
	
	for i in range(count):
		choices.append(temp_pool[i])
		
	return choices

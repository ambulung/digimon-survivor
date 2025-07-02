extends Node2D

# We'll need to know where the projectile scene is.
@export var projectile_scene: PackedScene

@onready var timer = $Timer

# Stats that will be upgraded
var level = 1
var damage = 5.0
var cooldown = 2.0

func _ready():
	timer.wait_time = cooldown
	timer.timeout.connect(attack)
	timer.start()

func attack():
	if not projectile_scene: return
	
	# Find a random enemy to target (simple example)
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		enemies.shuffle()
		var target = enemies[0]
		
		var projectile = projectile_scene.instantiate()
		# We need the projectile to be added to the main game world, not this weapon node
		get_tree().root.get_child(0).add_child(projectile)
		projectile.global_position = get_owner().global_position # Start from player
		projectile.direction = projectile.global_position.direction_to(target.global_position)

# This is the key function the Player will call!
func set_level(new_level: int):
	level = new_level
	match level:
		1: # Base stats (when acquired)
			damage = 5.0
			cooldown = 2.0
		2: # First upgrade
			damage = 8.0 # More damage
			cooldown = 2.0
		3: # Second upgrade
			damage = 8.0
			cooldown = 1.5 # Faster attack
		_:
			print("Weapon reached max level or level not defined.")
	
	timer.wait_time = cooldown
	print("BubbleWeapon upgraded to level ", level)

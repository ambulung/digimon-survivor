extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_buffer: float = 100.0 # Minimum distance from player

@onready var player = $digimon1
@onready var enemy_spawner = $EnemySpawner

func _ready():
	randomize() # Initialize random number generator
	enemy_spawner.timeout.connect(_on_enemy_spawner_timeout)

func _on_enemy_spawner_timeout():
	if not enemy_scene or not player or player.is_dead:
		return
	
	# Set a proper spawn radius, e.g., 300 pixels away from player minimum
	var spawn_radius: float = spawn_buffer
	
	# Generate a random angle and direction
	var random_angle = randf_range(0, TAU) # TAU = 2 * PI in Godot
	var offset = Vector2.RIGHT.rotated(random_angle) * spawn_radius
	
	# Get final spawn position
	var spawn_position = player.global_position + offset
	
	# Instantiate and position the enemy
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	add_child(enemy)

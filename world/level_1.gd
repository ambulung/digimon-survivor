# World.gd
extends Node2D

# --- EXPORTS (ASSIGN IN INSPECTOR) ---
@export var enemy_scene: PackedScene
@export var tile_set: TileSet # <-- Drag your TileSet resource here from the FileSystem

# --- CONSTANTS ---
const CHUNK_SIZE = Vector2i(32, 32)
const LOAD_RADIUS = 2

# Z-Index constants for render order
const Z_INDEX_FLOOR = -10
const Z_INDEX_CHARACTERS = 0

# --- SCENE NODES ---
@onready var player = $digimon1
@onready var enemy_spawner = $EnemySpawner
# Get a reference to the collision shape that defines our spawn box
@onready var spawn_shape: CollisionShape2D = $digimon1/SpawnArea/CollisionShape2D

# --- WORLD STATE VARIABLES ---
var active_chunks: Dictionary = {}
var current_chunk_coord: Vector2i = Vector2i.ZERO
var noise: FastNoiseLite


func _ready():
	if not player or not tile_set or not spawn_shape:
		push_error("A required node or resource is missing! Check Player, TileSet, and SpawnArea setup.")
		get_tree().quit() # Exit if setup is wrong
		
	enemy_spawner.timeout.connect(_on_enemy_spawner_timeout)
	
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.03
	
	current_chunk_coord = _get_chunk_coord_from_pos(player.global_position)
	update_chunks()


func _process(_delta):
	var new_chunk_coord = _get_chunk_coord_from_pos(player.global_position)
	if new_chunk_coord != current_chunk_coord:
		current_chunk_coord = new_chunk_coord
		update_chunks()


# --- CHUNK MANAGEMENT (No changes here) ---

func _get_chunk_coord_from_pos(pos: Vector2) -> Vector2i:
	var tile_pixel_size = tile_set.tile_size
	var chunk_pixel_size = CHUNK_SIZE * tile_pixel_size
	return Vector2i(floor(pos.x / chunk_pixel_size.x), floor(pos.y / chunk_pixel_size.y))

func update_chunks():
	var chunks_to_remove = active_chunks.keys()
	
	for y in range(current_chunk_coord.y - LOAD_RADIUS, current_chunk_coord.y + LOAD_RADIUS + 1):
		for x in range(current_chunk_coord.x - LOAD_RADIUS, current_chunk_coord.x + LOAD_RADIUS + 1):
			var chunk_coord = Vector2i(x, y)
			chunks_to_remove.erase(chunk_coord)
			
			if not active_chunks.has(chunk_coord):
				generate_chunk(chunk_coord)

	for chunk_coord_to_remove in chunks_to_remove:
		if active_chunks.has(chunk_coord_to_remove):
			active_chunks[chunk_coord_to_remove].queue_free()
			active_chunks.erase(chunk_coord_to_remove)

func generate_chunk(chunk_coord: Vector2i):
	var chunk = TileMap.new()
	chunk.tile_set = tile_set
	chunk.z_index = Z_INDEX_FLOOR
	add_child(chunk)
	
	var tile_pixel_size = tile_set.tile_size
	chunk.global_position = chunk_coord * CHUNK_SIZE * tile_pixel_size
	
	for y in range(CHUNK_SIZE.y):
		for x in range(CHUNK_SIZE.x):
			var global_tile_coord = (chunk_coord * CHUNK_SIZE) + Vector2i(x, y)
			var noise_val = noise.get_noise_2d(global_tile_coord.x, global_tile_coord.y)
			
			var source_id = 0
			var tile_atlas_coord: Vector2i
			
			if noise_val > 0.2:
				tile_atlas_coord = Vector2i(0, 0) # Your grass tile
			else:
				tile_atlas_coord = Vector2i(1, 0) # Your dirt tile
			
			chunk.set_cell(0, Vector2i(x, y), source_id, tile_atlas_coord)
	
	active_chunks[chunk_coord] = chunk


# --- ENEMY SPAWNING (UPDATED: NO LIMIT) ---

func _on_enemy_spawner_timeout():
	# Initial check
	if not enemy_scene or not player or player.is_dead:
		return

	# Get the spawn rectangle from our visual SpawnArea node
	var shape: RectangleShape2D = spawn_shape.shape
	var shape_size = shape.size
	var center_pos = spawn_shape.global_position
	var spawn_rect = Rect2(center_pos - shape_size / 2.0, shape_size)
	
	# Pick a random position on the edge of this rectangle
	var spawn_pos = Vector2.ZERO
	var side = randi_range(0, 3) # 0: top, 1: bottom, 2: left, 3: right

	match side:
		0: # Top edge
			spawn_pos.x = randf_range(spawn_rect.position.x, spawn_rect.end.x)
			spawn_pos.y = spawn_rect.position.y
		1: # Bottom edge
			spawn_pos.x = randf_range(spawn_rect.position.x, spawn_rect.end.x)
			spawn_pos.y = spawn_rect.end.y
		2: # Left edge
			spawn_pos.x = spawn_rect.position.x
			spawn_pos.y = randf_range(spawn_rect.position.y, spawn_rect.end.y)
		3: # Right edge
			spawn_pos.x = spawn_rect.end.x
			spawn_pos.y = randf_range(spawn_rect.position.y, spawn_rect.end.y)
			
	# Spawn the enemy
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	enemy.z_index = Z_INDEX_CHARACTERS
	add_child(enemy)

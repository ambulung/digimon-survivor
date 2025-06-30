extends CharacterBody2D

# --- EXPORTED VARIABLES ---
@export_group("Stats")
@export var speed = 300.0
@export var health = 100.0

@export_group("Combat")
# We will change this variable when we digivolve
var attack_scene: PackedScene
@export var botamon_attack_scene: PackedScene
@export var koromon_attack_scene: PackedScene # Drag koromon_attack.tscn here

@export_group("Evolution")
# Drag the SpriteFrames resources for each Digimon form here
@export var botamon_sprite_frames: SpriteFrames
@export var koromon_sprite_frames: SpriteFrames

# --- INTERNAL VARIABLES ---
# Leveling
var level = 1
var current_xp = 0.0
var xp_to_next_level = 50.0

var is_dead = false
var last_move_direction = Vector2.RIGHT

# --- NODE REFERENCES ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D # Get the collision shape
@onready var attack_timer = $Timer
@onready var health_bar = $ProgressBar
@onready var xp_bar = $XpBar # Get the new XP bar


# --- GODOT BUILT-IN FUNCTIONS ---
func _ready():
	# Initial setup
	health_bar.max_value = health
	health_bar.value = health
	update_xp_bar()
	
	# Set initial form to Botamon
	digivolve(botamon_sprite_frames, botamon_attack_scene, 0.8) # 0.8 is scale
	
	# Connect signals
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta):
	if is_dead: return

	# Movement
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO: last_move_direction = direction
	velocity = direction * speed
	move_and_slide()
	
	# Graphics
	update_animation()
	update_sprite_flip()
	
	# --- TESTING INPUTS ---
	if Input.is_action_just_pressed("ui_accept"): # Spacebar
		take_damage(10.0)
	if Input.is_action_just_pressed("ui_accept"): # Shift Key
		add_xp(10.0)

# --- LEVELING AND EVOLUTION ---
func add_xp(amount: float):
	current_xp += amount
	print("Gained", amount, "XP. Total:", current_xp, "/", xp_to_next_level)
	
	# Check for Level Up
	while current_xp >= xp_to_next_level:
		level_up()
		
	update_xp_bar()

func level_up():
	level += 1
	# Carry over extra XP
	current_xp -= xp_to_next_level
	# Calculate XP for the *next* level
	xp_to_next_level += 10.0
	print("LEVEL UP! Reached level", level)
	
	# Check if we should digivolve
	if level == 2: # Digivolve to Koromon at level 2
		digivolve(koromon_sprite_frames, koromon_attack_scene, 1.0) # 1.0 is scale

func digivolve(new_sprite_frames: SpriteFrames, new_attack: PackedScene, new_scale: float):
	print("Digivolving!")
	# Change visuals
	animated_sprite.sprite_frames = new_sprite_frames
	animated_sprite.scale = Vector2(new_scale, new_scale)
	collision_shape.scale = Vector2(new_scale, new_scale)
	# Change attack
	attack_scene = new_attack
	# Simple flash effect
	flash_on_damage() 

func update_xp_bar():
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp


# --- OTHER FUNCTIONS (Mostly unchanged) ---

func _on_attack_timer_timeout():
	if is_dead or not attack_scene: return
	animated_sprite.play("attack")
	var projectile = attack_scene.instantiate()
	projectile.direction = last_move_direction
	projectile.global_position = global_position
	get_parent().add_child(projectile)

func take_damage(amount: float):
	if is_dead: return
	flash_on_damage()
	health -= amount
	health_bar.value = health
	if health <= 0.0: die()

func flash_on_damage():
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func die():
	is_dead = true
	velocity = Vector2.ZERO
	attack_timer.stop()
	animated_sprite.play("dead")
	health_bar.hide()
	xp_bar.hide()
	
func update_animation():
	if animated_sprite.is_playing() and (animated_sprite.animation == "attack" or animated_sprite.animation == "dead"):
		return
	if velocity.length() > 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func update_sprite_flip():
	if last_move_direction.x < 0:
		animated_sprite.flip_h = true
	elif last_move_direction.x > 0:
		animated_sprite.flip_h = false

func _on_animation_finished():
	if animated_sprite.animation == "attack":
		update_animation()

extends CharacterBody2D

# -----------------------------------------------------------------------------
# SIGNALS - These are broadcasts the UI can listen to.
# -----------------------------------------------------------------------------
signal xp_changed(current_xp, xp_to_next_level)
signal level_changed(new_level)

# -----------------------------------------------------------------------------
# EXPORTED VARIABLES - Configure these in the Godot Inspector.
# -----------------------------------------------------------------------------
@export_group("Stats")
@export var speed = 300.0
@export var health = 100.0

@export_group("Combat")
var attack_scene: PackedScene
@export var botamon_attack_scene: PackedScene
@export var koromon_attack_scene: PackedScene

@export_group("Evolution")
@export var botamon_sprite_frames: SpriteFrames
@export var koromon_sprite_frames: SpriteFrames

# -----------------------------------------------------------------------------
# INTERNAL VARIABLES
# -----------------------------------------------------------------------------
var level = 1
var current_xp = 0.0
var xp_to_next_level = 50.0
var is_dead = false
var last_move_direction = Vector2.RIGHT

# -----------------------------------------------------------------------------
# NODE REFERENCES
# -----------------------------------------------------------------------------
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var attack_timer = $Timer
@onready var health_bar = $ProgressBar


# -----------------------------------------------------------------------------
# GODOT BUILT-IN FUNCTIONS
# -----------------------------------------------------------------------------
func _ready():
	# Set up health bar
	health_bar.max_value = health
	health_bar.value = health
	
	# Emit signals for the UI
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	emit_signal("level_changed", level)
	
	# Set the starting form
	digivolve(botamon_sprite_frames, botamon_attack_scene, 0.8)
	
	# Connect internal signals
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta):
	if is_dead: return

	# Handle player movement
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO: last_move_direction = direction
	velocity = direction * speed
	move_and_slide()
	
	# Update player graphics
	update_animation()
	update_sprite_flip()
	
	# --- TESTING INPUTS ---
	if Input.is_action_just_pressed("ui_accept"): take_damage(10.0)
	if Input.is_action_just_pressed("ui_accept"): add_xp(10.0)


# -----------------------------------------------------------------------------
# CUSTOM GAMEPLAY FUNCTIONS
# -----------------------------------------------------------------------------

# This function now correctly spawns the projectile at the player's center.
# The Collision Layer/Mask system prevents self-damage.
func _on_attack_timer_timeout():
	if is_dead or not attack_scene:
		return
		
	animated_sprite.play("attack")
	
	var projectile = attack_scene.instantiate()
	projectile.direction = last_move_direction
	
	# Spawning at the exact center. No offset needed.
	projectile.global_position = global_position
	
	get_parent().add_child(projectile)

func add_xp(amount: float):
	current_xp += amount
	while current_xp >= xp_to_next_level: level_up()
	emit_signal("xp_changed", current_xp, xp_to_next_level)

func level_up():
	level += 1
	current_xp -= xp_to_next_level
	xp_to_next_level += 10.0
	emit_signal("level_changed", level)
	if level == 2: digivolve(koromon_sprite_frames, koromon_attack_scene, 1.0)

func digivolve(new_sprite_frames: SpriteFrames, new_attack: PackedScene, new_scale: float):
	print("Digivolving!")
	animated_sprite.sprite_frames = new_sprite_frames
	animated_sprite.scale = Vector2(new_scale, new_scale)
	collision_shape.scale = Vector2(new_scale, new_scale)
	attack_scene = new_attack
	flash_on_damage() 

func take_damage(amount: float):
	if is_dead: return
	flash_on_damage()
	health -= amount
	health_bar.value = health
	if health <= 0.0: die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	attack_timer.stop()
	animated_sprite.play("dead")
	health_bar.hide()

func flash_on_damage():
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	
# -----------------------------------------------------------------------------
# ANIMATION HELPER FUNCTIONS
# -----------------------------------------------------------------------------
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

# This function is connected to the PickupArea's "area_entered" signal
func _on_pickup_area_area_entered(area):
	# Check if the thing that entered our magnet is an XpOrb
	if area is XpOrb:
		# Tell the orb to start flying towards us
		area.start_homing(self)

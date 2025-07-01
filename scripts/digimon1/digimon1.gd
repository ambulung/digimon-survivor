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

# NEW: The UI scene to show when the player levels up.
@export_group("UI")
@export var level_up_ui_scene: PackedScene

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
	# Press Enter/Space to test taking damage and adding XP
	if Input.is_action_just_pressed("ui_accept"): 
		add_xp(50.0) # Set XP high to easily test level up
	if Input.is_action_just_pressed("ui_page_down"):
		take_damage(10.0)


# -----------------------------------------------------------------------------
# CUSTOM GAMEPLAY FUNCTIONS
# -----------------------------------------------------------------------------

func _on_attack_timer_timeout():
	if is_dead or not attack_scene:
		return
		
	animated_sprite.play("attack")
	
	var projectile = attack_scene.instantiate()
	projectile.direction = last_move_direction
	projectile.global_position = global_position
	
	get_parent().add_child(projectile)

func add_xp(amount: float):
	if is_dead: return
	current_xp += amount
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	while current_xp >= xp_to_next_level:
		# Important: We just call level_up, which now handles pausing and showing the UI.
		# The loop ensures if you get enough XP for multiple levels, it will trigger multiple times.
		level_up()

# --- MODIFIED: This function now triggers the upgrade UI ---
func level_up():
	# 1. Pause the game and get choices from the global manager
	get_tree().paused = true
	var choices = UpgradeManager.get_random_upgrades(3)
	
	# 2. Instance and show the Level Up UI
	var ui = level_up_ui_scene.instantiate()
	get_tree().root.add_child(ui)
	
	# 3. Present the choices on the UI and connect to its 'upgrade_chosen' signal.
	# The game will remain paused until a choice is made.
	ui.present_choices(choices)
	ui.upgrade_chosen.connect(on_upgrade_chosen)

# --- NEW: This function receives the player's choice from the UI ---
func on_upgrade_chosen(upgrade: Upgrade):
	# 4. Apply the chosen upgrade's effects
	apply_upgrade(upgrade)
	
	# 5. Now perform the original level-up logic
	current_xp -= xp_to_next_level
	level += 1
	xp_to_next_level += 10.0
	
	# Emit signals to update the UI
	emit_signal("level_changed", level)
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	
	# Check for automatic digivolution (optional)
	if level == 2: 
		digivolve(koromon_sprite_frames, koromon_attack_scene, 1.0)

# --- NEW: This function contains the logic for what each upgrade does ---
func apply_upgrade(upgrade: Upgrade):
	match upgrade.id:
		"increase_speed":
			speed *= 1.10 # Increase speed by 10%
			print("Speed increased to: ", speed)
		"increase_max_health":
			health += 20
			health_bar.max_value = health
			health_bar.value = health_bar.max_value # Heal to full
			print("Max health increased to: ", health)
		"unlock_koromon_attack":
			attack_scene = koromon_attack_scene
			print("Attack changed to Koromon's attack")
		_:
			push_warning("Unknown upgrade ID selected: " + upgrade.id)


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

func _on_pickup_area_area_entered(area):
	if area is XpOrb:
		area.start_homing(self)

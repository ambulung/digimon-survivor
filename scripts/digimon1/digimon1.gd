extends CharacterBody2D

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal xp_changed(current_xp, xp_to_next_level)
signal level_changed(new_level)

# -----------------------------------------------------------------------------
# EXPORTED VARIABLES
# -----------------------------------------------------------------------------
@export_group("Stats")
@export var speed = 300.0
@export var health = 100.0

@export_group("Combat")
# This is the player's own default attack, separate from the upgradeable weapons.
@export var default_attack_scene: PackedScene

@export_group("Evolution")
@export var botamon_sprite_frames: SpriteFrames
@export var koromon_sprite_frames: SpriteFrames

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
var is_leveling_up = false # Flag to prevent infinite level-up loops

# Holds owned weapons and their current level, e.g., { "bubble_barrage": 2 }
var weapon_inventory: Dictionary = {}

# -----------------------------------------------------------------------------
# NODE REFERENCES
# -----------------------------------------------------------------------------
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var attack_timer = $Timer
@onready var health_bar = $ProgressBar
# A node to hold all our weapon scenes so they move with the player.
@onready var weapon_container = $WeaponContainer


# -----------------------------------------------------------------------------
# GODOT BUILT-IN FUNCTIONS
# -----------------------------------------------------------------------------
func _ready():
	health_bar.max_value = health
	health_bar.value = health
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	emit_signal("level_changed", level)
	
	digivolve(botamon_sprite_frames, default_attack_scene, 0.8)
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta):
	if is_dead: return
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO: last_move_direction = direction
	velocity = direction * speed
	move_and_slide()
	update_animation()
	update_sprite_flip()
	
	if Input.is_action_just_pressed("ui_accept"): add_xp(50.0)
	if Input.is_action_just_pressed("ui_page_down"): take_damage(10.0)


# -----------------------------------------------------------------------------
# CUSTOM GAMEPLAY FUNCTIONS
# -----------------------------------------------------------------------------

# This handles the player's innate attack, if any.
func _on_attack_timer_timeout():
	if is_dead or not default_attack_scene: return
	animated_sprite.play("attack")
	var projectile = default_attack_scene.instantiate()
	projectile.direction = last_move_direction
	projectile.global_position = global_position
	get_parent().add_child(projectile)

func add_xp(amount: float):
	if is_dead: return
	current_xp += amount
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	# Only start the level up process if we aren't already in it.
	if not is_leveling_up and current_xp >= xp_to_next_level:
		level_up()

func level_up():
	if is_leveling_up: return # Prevent infinite loop
	is_leveling_up = true
	
	get_tree().paused = true
	
	var choices = UpgradeManager.get_upgrade_choices(weapon_inventory, 3)
	
	if choices.is_empty():
		print("No upgrades available!")
		get_tree().paused = false
		is_leveling_up = false
		return
	
	var ui = level_up_ui_scene.instantiate()
	get_tree().root.add_child(ui)
	
	ui.present_choices(choices)
	ui.upgrade_chosen.connect(on_upgrade_chosen)

func on_upgrade_chosen(choice_data: Dictionary):
	apply_upgrade(choice_data)
	
	current_xp -= xp_to_next_level
	level += 1
	xp_to_next_level += 10.0
	
	emit_signal("level_changed", level)
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	
	is_leveling_up = false # Reset the flag
	
	# Optional: Check for automatic digivolution
	# if level == 2: digivolve(...)

	# Check if we have enough XP for a chain level-up
	if not is_leveling_up and current_xp >= xp_to_next_level:
		level_up()

# --- REWRITTEN with call_deferred fix ---
func apply_upgrade(choice_data: Dictionary):
	var weapon_data: WeaponUpgrade = choice_data["data"]
	var new_level: int = choice_data["level"]
	var weapon_id = weapon_data.id

	if new_level == 1:
		# Case 1: Acquiring a NEW weapon
		var weapon_instance = weapon_data.weapon_scene.instantiate()
		weapon_instance.name = weapon_id # Use the ID as the node name for easy lookup
		weapon_container.add_child(weapon_instance)
		print("Acquired new weapon: ", weapon_id)
	
	# Case 2: Update inventory for BOTH new weapons and upgrades
	weapon_inventory[weapon_id] = new_level
	
	# Find the weapon node we just added (or already had)
	var weapon_node = weapon_container.get_node(weapon_id)
	if weapon_node and weapon_node.has_method("set_level"):
		# We use call_deferred to wait until the next idle frame to call set_level.
		# This guarantees the weapon_node's _ready() function has run first.
		weapon_node.call_deferred("set_level", new_level)
	else:
		push_warning("Could not find weapon node or set_level method for ID: " + weapon_id)


func digivolve(new_sprite_frames: SpriteFrames, new_attack: PackedScene, new_scale: float):
	print("Digivolving!")
	animated_sprite.sprite_frames = new_sprite_frames
	animated_sprite.scale = Vector2(new_scale, new_scale)
	collision_shape.scale = Vector2(new_scale, new_scale)
	default_attack_scene = new_attack
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
	weapon_container.hide() 

func flash_on_damage():
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

# -----------------------------------------------------------------------------
# ANIMATION & UTILITY FUNCTIONS
# -----------------------------------------------------------------------------
func update_animation():
	if animated_sprite.is_playing() and (animated_sprite.animation == "attack" or animated_sprite.animation == "dead"): return
	if velocity.length() > 0: animated_sprite.play("walk")
	else: animated_sprite.play("idle")

func update_sprite_flip():
	if last_move_direction.x < 0: animated_sprite.flip_h = true
	elif last_move_direction.x > 0: animated_sprite.flip_h = false

func _on_animation_finished():
	if animated_sprite.animation == "attack": update_animation()

func _on_pickup_area_area_entered(area):
	if area is XpOrb: area.start_homing(self)

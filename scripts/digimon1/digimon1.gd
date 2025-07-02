extends CharacterBody2D

# SIGNALS
signal xp_changed(current_xp, xp_to_next_level)
signal level_changed(new_level)

# EXPORTED VARIABLES
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

@export_group("UI")
@export var level_up_ui_scene: PackedScene

# INTERNAL VARIABLES
var level = 1
var current_xp = 0.0
var xp_to_next_level = 50.0
var is_dead = false
var last_move_direction = Vector2.RIGHT
var is_leveling_up = false # Flag to prevent infinite loops

# NODE REFERENCES
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var attack_timer = $Timer
@onready var health_bar = $ProgressBar


func _ready():
	health_bar.max_value = health
	health_bar.value = health
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	emit_signal("level_changed", level)
	digivolve(botamon_sprite_frames, botamon_attack_scene, 0.8)
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

func _on_attack_timer_timeout():
	if is_dead or not attack_scene: return
	animated_sprite.play("attack")
	var projectile = attack_scene.instantiate()
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
	var choices = UpgradeManager.get_random_upgrades(3)
	
	var ui = level_up_ui_scene.instantiate()
	get_tree().root.add_child(ui)
	
	ui.present_choices(choices)
	ui.upgrade_chosen.connect(on_upgrade_chosen)

func on_upgrade_chosen(upgrade: Upgrade):
	apply_upgrade(upgrade)
	
	current_xp -= xp_to_next_level
	level += 1
	xp_to_next_level += 10.0
	
	emit_signal("level_changed", level)
	emit_signal("xp_changed", current_xp, xp_to_next_level)
	
	is_leveling_up = false # Reset the flag
	
	if level == 2: digivolve(koromon_sprite_frames, koromon_attack_scene, 1.0)

	# Check for a chain level up
	if not is_leveling_up and current_xp >= xp_to_next_level:
		level_up()

func apply_upgrade(upgrade: Upgrade):
	match upgrade.id:
		"increase_speed":
			speed *= 1.10
			print("Speed increased to: ", speed)
		"increase_max_health":
			health += 20
			health_bar.max_value = health
			health_bar.value = health_bar.max_value
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

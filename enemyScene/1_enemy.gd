extends CharacterBody2D

@export var speed = 150.0
@export var contact_damage = 5.0
@export var health = 30.0

var player: CharacterBody2D = null
var player_in_range = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var damage_area = $DamageArea
@onready var damage_timer = $DamageTimer
@export var xp_drop_scene: PackedScene

# A flag to prevent die() from being called multiple times
var is_dying = false

func _ready():
	# FIX 1: Make the material unique to this enemy instance.
	# This prevents all enemies from dissolving or flashing at the same time.
	if animated_sprite.material:
		animated_sprite.material = animated_sprite.material.duplicate()

	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		push_warning("Enemy could not find a valid player node!")
		return

	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)
	damage_timer.timeout.connect(_on_damage_timer_timeout)

func _physics_process(_delta):
	# Stop moving if we are dying
	if not player or player.is_dead or is_dying:
		velocity = Vector2.ZERO
		return
	
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false

func take_damage(amount: float):
	# Don't take damage if already dying
	if is_dying:
		return
		
	health -= amount
	print("Enemy took", amount, "damage. Health is now:", health)
	
	flash_on_damage()
	
	if health <= 0:
		die()

# --- FINAL die() FUNCTION ---
func die():
	# Check the flag to ensure this code only runs once
	if is_dying:
		return
	is_dying = true
	
	# Stop processing physics and disable collision
	set_physics_process(false)
	damage_area.get_node("CollisionShape2D").set_deferred("disabled", true)

	# Only drop something if a scene was assigned in the editor
	if xp_drop_scene:
		var xp_orb = xp_drop_scene.instantiate()
		xp_orb.global_position = self.global_position
		get_parent().add_child(xp_orb)
	
	# NEW: Play the "death" sprite animation.
	# Make sure you have an animation named "death" in your AnimatedSprite2D!
	animated_sprite.play("death")

	# Create a tween to handle the dissolve shader animation
	var tween = create_tween()
	
	# Animate the shader's 'progress' parameter from 0 to 1 over 1.2 seconds.
	# The death animation will play at the same time as this dissolve happens.
	if animated_sprite.material is ShaderMaterial:
		tween.tween_property(
			animated_sprite.material, "shader_parameter/progress", 1.0, 1.2
		).set_ease(Tween.EASE_IN)

	# IMPORTANT: Wait for the tween to finish before calling queue_free().
	tween.finished.connect(queue_free)


func flash_on_damage():
	var tween = create_tween()
	# Make sure not to interfere with the dying animation
	if not is_dying:
		tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func _on_damage_timer_timeout():
	if player_in_range and player and not player.is_dead:
		player.take_damage(contact_damage)

func _on_damage_area_body_entered(body):
	if body == player:
		player_in_range = true

func _on_damage_area_body_exited(body):
	if body == player:
		player_in_range = false

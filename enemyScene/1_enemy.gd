extends CharacterBody2D

@export var speed = 150.0
@export var contact_damage = 5.0
# NEW: Enemy's health. Exporting it makes it easy to change per enemy type.
@export var health = 30.0

var player: CharacterBody2D = null
var player_in_range = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var damage_area = $DamageArea
@onready var damage_timer = $DamageTimer
@export var xp_drop_scene: PackedScene

func _ready():
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		push_warning("Enemy could not find a valid player node!")
		return

	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)
	damage_timer.timeout.connect(_on_damage_timer_timeout)

func _physics_process(_delta):
	if not player or player.is_dead:
		velocity = Vector2.ZERO
		return
	
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false

# --- NEW AND MODIFIED FUNCTIONS ---

# NEW: This function is called by projectiles to deal damage.
func take_damage(amount: float):
	health -= amount
	print("Enemy took", amount, "damage. Health is now:", health)
	
	# Play a flash effect for feedback
	flash_on_damage()
	
	if health <= 0:
		die()

# NEW: A function to handle the enemy's death.
func die():
	# Only drop something if a scene was assigned in the editor
	if xp_drop_scene:
		# Create an instance of the XP orb
		var xp_orb = xp_drop_scene.instantiate()
		# Place it where the enemy died
		xp_orb.global_position = self.global_position
		# Add it to the main game world
		get_parent().add_child(xp_orb)
	
	# Now the enemy can disappear
	queue_free()

# NEW: A visual effect for taking damage.
func flash_on_damage():
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

# MODIFIED: Renamed variable for clarity
func _on_damage_timer_timeout():
	if player_in_range and player and not player.is_dead:
		player.take_damage(contact_damage)

func _on_damage_area_body_entered(body):
	if body == player:
		player_in_range = true

func _on_damage_area_body_exited(body):
	if body == player:
		player_in_range = false

# xp_orb.gd
class_name XpOrb
extends Area2D

@export var xp_value: float = 10.0
@export var homing_speed: float = 600.0

var target: Node2D = null
var is_homing: bool = false
var collected: bool = false # Guard to prevent multiple XP triggers

func _ready():
	self.body_entered.connect(_on_body_entered)

# This is called by the player's magnet to start homing
func start_homing(player_node: Node2D):
	target = player_node
	is_homing = true

func _physics_process(delta):
	if not is_homing or not is_instance_valid(target):
		return

	var direction = global_position.direction_to(target.global_position)
	global_position += direction * homing_speed * delta

	# Extra collision fallback in case body_entered doesn't trigger
	if overlaps_body(target):
		collect()

# Called when Area2D collides with a PhysicsBody2D (ideally the player)
func _on_body_entered(body):
	if body == target:
		collect()

# Prevents multiple XP collections
func collect():
	if collected:
		return
	collected = true
	target.add_xp(xp_value)
	queue_free()

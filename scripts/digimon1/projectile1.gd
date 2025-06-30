class_name BubbleBlow
extends Area2D

@export var speed = 400.0
@export var damage = 10.0

var direction = Vector2.RIGHT

func _ready():
	self.body_entered.connect(_on_body_entered)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# THE FIX: Use call_deferred to prevent physics crash
		body.call_deferred("take_damage", damage)
		
	queue_free()

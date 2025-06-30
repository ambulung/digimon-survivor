class_name BubbleBlow
extends Area2D

@export var speed = 400

var direction = Vector2.RIGHT

func _ready():
	# Destroy the bubble after 2 seconds to prevent clutter
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _process(delta):
	# Move the bubble every frame
	position += direction * speed * delta

# This function is ready for when we add enemies
func _on_body_entered(body):
	pass

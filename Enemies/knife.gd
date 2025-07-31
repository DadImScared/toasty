# Knife.gd - Attach this to your knife scene root node (Area2D)
extends Area2D

signal hit_player

func _ready():
	# Add to scrolling objects group so it moves with the world
	add_to_group("scrolling_objects")
	add_to_group("knives")

	# Connect the collision detection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Toasty":
		print("Knife hit Toasty!")
		hit_player.emit()
		queue_free()  # Remove the knife after hit

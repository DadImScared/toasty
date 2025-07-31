# Main.gd - attach this to your Main (Node2D)
extends Node2D

@onready var toasty = $Toasty
@onready var parallax_bg = $Parallax2D

# Spawning variables
@export var collectible_spawn_rate = 2.0  # seconds between spawns
@export var scroll_speed = 100  # Should match your background scroll speed

# Track world position (since background scrolls)
var world_distance = 0.0
var last_collectible_spawn = 0.0

# Preload scenes
var collectible_scene = preload("res://Collectibles/collectible_item.tscn")

# Preload all collectible resources
var collectible_resources = [
	preload("res://Resources/Collectibles/avocado.tres"),
	preload("res://Resources/Collectibles/tomato.tres"),
	preload("res://Resources/Collectibles/strawberry.tres"),
	preload("res://Resources/Collectibles/orange.tres")
]

func _ready():
	pass

func _process(delta):
	# Track how far we've "traveled"
	world_distance += scroll_speed * delta

	# Spawn collectibles at intervals
	if world_distance > last_collectible_spawn + (scroll_speed * collectible_spawn_rate):
		spawn_collectible()
		last_collectible_spawn = world_distance

	# Move existing objects left (simulate world movement)
	move_objects_left(delta)

func spawn_collectible():
	var collectible = collectible_scene.instantiate()


	# Randomly assign one of the collectible types
	collectible.collectible_data = collectible_resources[randi() % collectible_resources.size()]
	add_child(collectible)

	# Spawn off-screen to the right
	var spawn_x = get_viewport().size.x
	var spawn_y = randf_range(-200, 200)  # Random height in kitchen
	collectible.global_position = Vector2(spawn_x, spawn_y)

	# Connect collection signal
	collectible.collected.connect(_on_collectible_collected)

func move_objects_left(delta):
	# Move all collectibles left to simulate scrolling world
	for child in get_children():
		if child.is_in_group("scrolling_objects"):
			child.global_position.x -= scroll_speed * delta

			# Remove objects when completely off-screen (left side)
			var removal_threshold = -get_viewport().size.x
			if child.global_position.x < removal_threshold:
				child.queue_free()

func _on_collectible_collected(collectible):
	print("Collected: ", collectible.name, " Worth: ", collectible.value)
	# Update score, etc.
	# You can add score handling here later

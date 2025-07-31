# main.gd - Updated with knife spawning system
extends Node2D

@onready var toasty = $Toasty
@onready var parallax_bg = $Parallax2D
@onready var ui = $UI

# Spawning variables
@export var collectible_spawn_rate = 2.0  # seconds between collectible spawns
@export var knife_spawn_rate = 4.0  # seconds between knife spawns (start easier)
@export var scroll_speed = 100  # Should match your background scroll speed
@export var knife_speed_multiplier = 1.5  # Knives move 50% faster

# Track world position (since background scrolls)
var world_distance = 0.0
var last_collectible_spawn = 0.0
var last_knife_spawn = 0.0

# Preload scenes
var collectible_scene = preload("res://Collectibles/collectible_item.tscn")
var knife_scene = preload("res://Enemies/knife.tscn")
var game_over_ui_scene = preload("res://UI/GameOver/game_over_ui.tscn")  # Updated path

# Preload all collectible resources
var collectible_resources = [
	preload("res://Resources/Collectibles/avocado.tres"),
	preload("res://Resources/Collectibles/tomato.tres"),
	preload("res://Resources/Collectibles/strawberry.tres"),
	preload("res://Resources/Collectibles/orange.tres")
]

func _ready():
	# Start the game when main scene loads
	GameManager.start_new_game()

	# Connect to game manager signals if needed
	GameManager.game_over.connect(_on_game_over)

func _process(delta):
	# Only process game logic if game is active
	if not GameManager.is_playing():
		return

	# Track how far we've "traveled"
	world_distance += scroll_speed * delta

	# Spawn collectibles at intervals
	if world_distance > last_collectible_spawn + (scroll_speed * collectible_spawn_rate):
		spawn_collectible()
		last_collectible_spawn = world_distance

	# Spawn knives at intervals
	if world_distance > last_knife_spawn + (scroll_speed * knife_spawn_rate):
		spawn_knife()
		last_knife_spawn = world_distance

	# Move existing objects left (simulate world movement)
	move_objects_left(delta)

func spawn_collectible():
	var collectible = collectible_scene.instantiate()

	# Randomly assign one of the collectible types
	collectible.collectible_data = collectible_resources[randi() % collectible_resources.size()]
	add_child(collectible)

	# Spawn off-screen to the right
	var spawn_x = get_viewport().size.x + 50  # A bit further off screen
	var spawn_y = randf_range(-200, 200)  # Random height in kitchen
	collectible.global_position = Vector2(spawn_x, spawn_y)

	# Connect collection signal to GameManager
	collectible.collected.connect(_on_collectible_collected)

func spawn_knife():
	var knife = knife_scene.instantiate()
	add_child(knife)

	# Spawn off-screen to the right
	var spawn_x = get_viewport().size.x + 50
	var spawn_y = randf_range(-200, 200)  # Random height in kitchen
	knife.global_position = Vector2(spawn_x, spawn_y)

	# Connect collision signal
	knife.hit_player.connect(_on_knife_hit_player)

func move_objects_left(delta):
	# Move all collectibles and knives left to simulate scrolling world
	for child in get_children():
		if child.is_in_group("scrolling_objects"):
			var move_speed = scroll_speed

			# Knives move faster for extra danger
			if child.is_in_group("knives"):
				move_speed *= knife_speed_multiplier

			child.global_position.x -= move_speed * delta

			# Remove objects when completely off-screen (left side)
			var removal_threshold = -get_viewport().size.x
			if child.global_position.x < removal_threshold:
				child.queue_free()

func _on_collectible_collected(collectible):
	"""Handle collectible collection through GameManager"""
	GameManager.collect_item(collectible)

func _on_knife_hit_player():
	"""Handle when player hits a knife - GAME OVER!"""
	print("Player hit by knife - Game Over!")
	GameManager.end_game()

func _on_game_over(final_score: int, is_high_score: bool, star_rating: int, collectible_stats: Dictionary):
	"""Handle game over state - Create and show GameOverUI"""
	print("Main scene received game over: Score=", final_score, ", New High Score=", is_high_score, ", Stars=", star_rating)

	# Create the GameOverUI dynamically (now it's already a CanvasLayer)
	var game_over_ui = game_over_ui_scene.instantiate()
	ui.add_child(game_over_ui)

	# Wait one frame then show
	await get_tree().process_frame
	game_over_ui.show_game_over_screen(final_score, is_high_score, collectible_stats)

# Optional: Add a way to trigger game over manually (for testing)
func trigger_game_over():
	"""Call this when player hits an obstacle or falls off screen"""
	GameManager.end_game()

func _on_retry_pressed():
	"""Handle retry button - GameOverUI will be cleaned up automatically when scene reloads"""
	print("Retry pressed - restarting game")
	# GameManager.restart_game() will reload the scene, cleaning up the GameOverUI

extends Node2D

@onready var toasty = $Toasty
@onready var parallax_bg = $Parallax2D
@onready var ui = $UI
@onready var spawn_path = $SpawnPath2D  # Add this node to your scene manually

# Spawning variables
@export var collectible_spawn_rate = 1.0
@export var knife_spawn_rate = 1.0
@export var scroll_speed = 150
@export var knife_speed_multiplier = 1.4

var world_distance = 0.0
var last_collectible_spawn = 0.0
var last_knife_spawn = 0.0

var collectible_scene = preload("res://Collectibles/collectible_item.tscn")
var knife_scene = preload("res://Enemies/knife.tscn")
var game_over_ui_scene = preload("res://UI/GameOver/game_over_ui.tscn")
var cat_scene = preload("res://Enemies/cat.tscn")
var cat_attack = preload("res://Enemies/cat_attack.tscn")
var score_popup_scene = preload("res://UI/score_popup.tscn")  # Add score popup

var collectible_resources = [
	preload("res://Resources/Collectibles/avocado.tres"),
	preload("res://Resources/Collectibles/tomato.tres"),
	preload("res://Resources/Collectibles/strawberry.tres"),
	preload("res://Resources/Collectibles/orange.tres")
]

func _ready():
	GameManager.start_new_game()
	GameManager.game_over.connect(_on_game_over)
	spawn_cats_forever()

func spawn_cat():
	var new_cat = cat_scene.instantiate()
	add_child(new_cat)
	new_cat.cat_announcement_finished.connect(_on_cat_pounce)

func spawn_cats_forever() -> void:
	while GameManager.is_playing():
		spawn_cat()
		var wait_time = randf_range(2.0, 4.0)
		await get_tree().create_timer(wait_time).timeout

func _on_cat_pounce(stage):
	if stage == "full_sequence":
		var new_attack = cat_attack.instantiate()
		new_attack.hit_player.connect(on_player_hit)
		add_child(new_attack)

func on_player_hit():
	GameManager.end_game()

func _process(delta):
	if not GameManager.is_playing():
		return

	world_distance += scroll_speed * delta

	if world_distance > last_collectible_spawn + (scroll_speed * collectible_spawn_rate):
		spawn_collectible()
		last_collectible_spawn = world_distance

	if world_distance > last_knife_spawn + (scroll_speed * knife_spawn_rate):
		spawn_knife()
		last_knife_spawn = world_distance

	move_objects_left(delta)

func get_spawn_position_from_path() -> Vector2:
	var path_follow = PathFollow2D.new()
	spawn_path.add_child(path_follow)
	path_follow.progress_ratio = randf()
	var spawn_position = path_follow.global_position
	path_follow.queue_free()
	return spawn_position

func spawn_collectible():
	var collectible = collectible_scene.instantiate()
	collectible.collectible_data = collectible_resources[randi() % collectible_resources.size()]
	add_child(collectible)

	collectible.global_position = get_spawn_position_from_path()
	collectible.collected.connect(_on_collectible_collected)

func spawn_knife():
	var knife = knife_scene.instantiate()
	add_child(knife)

	knife.global_position = get_spawn_position_from_path()
	knife.hit_player.connect(_on_knife_hit_player)

func move_objects_left(delta):
	for child in get_children():
		if child.is_in_group("scrolling_objects"):
			var move_speed = scroll_speed
			if child.is_in_group("knives"):
				move_speed *= knife_speed_multiplier

			child.global_position.x -= move_speed * delta

			var removal_threshold = -get_viewport().size.x
			if child.global_position.x < removal_threshold:
				child.queue_free()

func _on_collectible_collected(collectible):
	# Show score popup at Toasty's position
	show_score_popup(collectible.value, toasty.global_position)

	# Handle the collection through GameManager
	GameManager.collect_item(collectible)

func show_score_popup(score_value: int, world_pos: Vector2):
	var popup = score_popup_scene.instantiate()
	add_child(popup)

	# Get current score info from GameManager
	var current_score = GameManager.get_current_score()
	var high_score = GameManager.get_high_score()

	# Show the popup with current game state
	popup.show_score_popup(score_value, current_score, high_score, world_pos)

func _on_knife_hit_player():
	print("Player hit by knife - Game Over!")
	GameManager.end_game()

func _on_game_over(final_score: int, is_high_score: bool, star_rating: int, collectible_stats: Dictionary):
	print("Main scene received game over: Score=", final_score, ", New High Score=", is_high_score, ", Stars=", star_rating)

	var game_over_ui = game_over_ui_scene.instantiate()
	ui.add_child(game_over_ui)

	await get_tree().process_frame
	game_over_ui.show_game_over_screen(final_score, is_high_score, collectible_stats)

func trigger_game_over():
	GameManager.end_game()

func _on_retry_pressed():
	print("Retry pressed - restarting game")

func _on_pause_pressed() -> void:
	get_tree().paused = !get_tree().paused

# GameManager.gd - Singleton for managing game state (No Main Menu)
# Add this as an AutoLoad singleton in Project Settings -> AutoLoad
# Name: GameManager, Path: res://GameManager.gd

extends Node

# Signals for UI to connect to
signal score_changed(new_score: int, score_type: String)
signal game_over(final_score: int, is_high_score: bool, star_rating: int, collectible_stats: Dictionary)
signal game_started
signal game_paused
signal game_resumed

# Game states (simplified - no menu state)
enum GameState {
	PLAYING,
	PAUSED,
	GAME_OVER
}

# Game variables
var current_state: GameState = GameState.PLAYING
var current_score: int = 0
var high_score: int = 0
var is_game_active: bool = false

# Collectible tracking
var collectibles_collected: Dictionary = {}
var collectible_stats: Dictionary = {}

# Time-based scoring
@export var time_score_enabled: bool = true
@export var time_score_interval: float = 1.0  # seconds
@export var time_score_points: int = 1
var time_score_timer: float = 0.0

# Save file
const SAVE_FILE = "user://toasty_save.dat"

func _ready():
	# Load saved data on startup
	load_game_data()
	print("GameManager ready. High Score: ", high_score)

func _process(delta):
	# Handle time-based scoring during gameplay
	if is_game_active and time_score_enabled:
		time_score_timer += delta
		if time_score_timer >= time_score_interval:
			add_score(time_score_points, "time")
			time_score_timer = 0.0

func _input(event):
	# Handle pause with back button or escape (mobile back button)
	if event.is_action_pressed("ui_cancel") and current_state == GameState.PLAYING:
		toggle_pause()

# ===== GAME STATE MANAGEMENT =====

func start_new_game():
	"""Start a new game session"""
	current_score = 0
	current_state = GameState.PLAYING
	is_game_active = true
	time_score_timer = 0.0  # Reset timer

	# Reset collectible tracking
	collectibles_collected.clear()

	get_tree().paused = false

	print("Game started!")
	game_started.emit()
	score_changed.emit(current_score, "game_start")

func end_game():
	"""End the current game and check for high score"""
	if not is_game_active:
		return

	is_game_active = false
	current_state = GameState.GAME_OVER
	get_tree().paused = true

	# Check for new high score
	var is_high_score = false
	if current_score > high_score:
		high_score = current_score
		is_high_score = true
		save_game_data()
		print("New High Score: ", high_score)

	print("Game Over! Final Score: ", current_score)
	var stars = get_star_rating(current_score)
	game_over.emit(current_score, is_high_score, stars, collectibles_collected)

func pause_game():
	"""Pause the game"""
	if current_state != GameState.PLAYING:
		return

	current_state = GameState.PAUSED
	get_tree().paused = true
	print("Game paused")
	game_paused.emit()

func resume_game():
	"""Resume the game"""
	if current_state != GameState.PAUSED:
		return

	current_state = GameState.PLAYING
	get_tree().paused = false
	print("Game resumed")
	game_resumed.emit()

func toggle_pause():
	"""Toggle between pause and play"""
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()

func restart_game():
	"""Restart the current game"""
	get_tree().paused = false
	get_tree().reload_current_scene()

# ===== SCORING SYSTEM =====

func add_score(points: int, score_type: String = "collectible"):
	"""Add points to current score"""
	if not is_game_active:
		return

	current_score += points
	print("Score +", points, " | Total: ", current_score, " (", score_type, ")")
	score_changed.emit(current_score, score_type)

func get_current_score() -> int:
	return current_score

func get_high_score() -> int:
	return high_score

# ===== COLLECTIBLE HANDLING =====

func collect_item(collectible: Resource):
	"""Handle when player collects an item"""
	if not is_game_active:
		return

	# Track collectible by name
	var collectible_name = "Unknown"
	var collectible_value = 10

	if collectible:
		collectible_name = collectible.get("name")
		collectible_value = collectible.get("value")

		# Update collectible count
		if collectibles_collected.has(collectible_name):
			collectibles_collected[collectible_name] += 1
		else:
			collectibles_collected[collectible_name] = 1

		print("Collected: ", collectible_name, " (Total: ", collectibles_collected[collectible_name], ")")

	# Add score
	add_score(collectible_value, "collectible")

# ===== SAVE/LOAD SYSTEM =====

func save_game_data():
	"""Save game data to file"""
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		var save_data = {
			"high_score": high_score,
			"version": "1.0"
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game data saved")
	else:
		print("Failed to save game data")

func load_game_data():
	"""Load game data from file"""
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found, using defaults")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			var save_data = json.data
			high_score = save_data.get("high_score", 0)
			print("Game data loaded successfully")
		else:
			print("Failed to parse save file")
	else:
		print("Failed to open save file")

# ===== COLLECTIBLE TRACKING =====

func get_collectible_stats() -> Dictionary:
	"""Get current collectible statistics"""
	return collectibles_collected.duplicate()

func get_total_collectibles() -> int:
	"""Get total number of collectibles collected this game"""
	var total = 0
	for collectible_name in collectibles_collected:
		total += collectibles_collected[collectible_name]
	return total

func get_star_rating(score: int) -> int:
	"""Calculate star rating (0-3) based on score"""
	# Adjust these thresholds based on your game balance
	if score >= 150:
		return 3  # 3 stars - Excellent!
	elif score >= 75:
		return 2  # 2 stars - Good job!
	elif score >= 25:
		return 1  # 1 star - Keep trying!
	else:
		return 0  # No stars - Try again!

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER

func get_state_name() -> String:
	match current_state:
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.GAME_OVER: return "GAME_OVER"
		_: return "UNKNOWN"

# ===== TIME-BASED SCORE CONFIGURATION =====

func set_time_scoring(enabled: bool, interval: float = 1.0, points: int = 1):
	"""Configure time-based scoring"""
	time_score_enabled = enabled
	time_score_interval = interval
	time_score_points = points
	print("Time scoring: ", "enabled" if enabled else "disabled",
		  " (", points, " points every ", interval, " seconds)")

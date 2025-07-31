# Scoreboard.gd - Standalone scoreboard that connects to GameManager (No Main Menu)
extends Control

@onready var current_score_label = $NinePatchRect/MarginContainer/CurrentScore
@onready var high_score_label = null  # You don't have a high score label in this setup
@onready var background_panel = $NinePatchRect  # Reference to the PNG background

# Configuration
@export var show_high_score: bool = false  # Set to false since you don't have a high score label
@export var score_prefix: String = "Score: "
@export var high_score_prefix: String = "Best: "
@export var animate_score_changes: bool = true

# Animation settings
var score_animation_duration: float = 0.3
var scale_bounce_amount: float = 1.2

func _ready():
	# Connect to GameManager signals
	if GameManager:
		GameManager.score_changed.connect(_on_score_changed)
		GameManager.game_started.connect(_on_game_started)
		GameManager.game_over.connect(_on_game_over)
	else:
		print("Warning: GameManager not found! Make sure it's added as AutoLoad singleton.")

	# Initial setup
	setup_initial_display()
	configure_visibility()

func setup_initial_display():
	"""Set up the initial score display"""
	if current_score_label:
		current_score_label.text = score_prefix + str(GameManager.get_current_score() if GameManager else 0)

	if show_high_score and high_score_label and GameManager:
		high_score_label.text = high_score_prefix + str(GameManager.get_high_score())

func configure_visibility():
	"""Configure which elements are visible"""
	if high_score_label:
		high_score_label.visible = show_high_score

# ===== SIGNAL HANDLERS =====

func _on_score_changed(new_score: int, score_type: String):
	"""Handle score changes from GameManager"""
	update_score_display(new_score, score_type)

func _on_game_started():
	"""Handle game start"""
	print("Scoreboard: Game started")
	update_score_display(0, "game_start")

func _on_game_over(final_score: int, is_high_score: bool, star_rating: int, collectible_stats: Dictionary):
	"""Handle game over"""
	print("Scoreboard: Game over - Final score: ", final_score, ", Stars: ", star_rating)

	# Update high score display if needed
	if is_high_score and show_high_score:
		update_high_score_display(final_score)

# ===== DISPLAY UPDATES =====

func update_score_display(score: int, score_type: String = ""):
	"""Update the current score display with optional animation"""
	if not current_score_label:
		print("Warning: current_score_label not found! Check your node path.")
		return

	current_score_label.text = score_prefix + str(score)

	# Only animate for collectibles, not time-based scoring
	if animate_score_changes and score_type == "collectible":
		animate_score_change()

func update_high_score_display(new_high_score: int):
	"""Update the high score display"""
	if not show_high_score or not high_score_label:
		return

	high_score_label.text = high_score_prefix + str(new_high_score)

	# Special animation for new high score
	if animate_score_changes:
		animate_new_high_score()

# ===== ANIMATIONS =====

func animate_score_change():
	"""Animate score change by scaling the PNG background"""
	if not background_panel:
		return

	var tween = create_tween()
	tween.tween_property(background_panel, "scale", Vector2(scale_bounce_amount, scale_bounce_amount), score_animation_duration * 0.5)
	tween.tween_property(background_panel, "scale", Vector2(1.0, 1.0), score_animation_duration * 0.5)

func animate_new_high_score():
	"""Special animation for new high score achievement - flash the PNG background"""
	if not background_panel or not show_high_score:
		return

	# Flash effect for new high score - animate the PNG background color
	var flash_tween = create_tween()
	flash_tween.set_loops(3)
	flash_tween.tween_property(background_panel, "modulate", Color.YELLOW, 0.2)
	flash_tween.tween_property(background_panel, "modulate", Color.WHITE, 0.2)

# ===== PUBLIC METHODS =====

func show_scoreboard():
	"""Show the scoreboard"""
	visible = true

func hide_scoreboard():
	"""Hide the scoreboard"""
	visible = false

func toggle_high_score_visibility(show: bool):
	"""Toggle high score visibility at runtime"""
	show_high_score = show
	configure_visibility()

	# Refresh display
	if GameManager and show_high_score:
		update_high_score_display(GameManager.get_high_score())

func set_score_prefix(prefix: String):
	"""Change the score prefix at runtime"""
	score_prefix = prefix
	if GameManager:
		update_score_display(GameManager.get_current_score())

func set_high_score_prefix(prefix: String):
	"""Change the high score prefix at runtime"""
	high_score_prefix = prefix
	if GameManager and show_high_score:
		update_high_score_display(GameManager.get_high_score())

# ===== UTILITY METHODS =====

func refresh_display():
	"""Manually refresh the scoreboard display"""
	if GameManager:
		update_score_display(GameManager.get_current_score())
		if show_high_score:
			update_high_score_display(GameManager.get_high_score())

# ===== TESTING METHODS (Remove in production) =====

func _input(event):
	# For testing - remove these in production
	if OS.is_debug_build():
		if event.is_action_pressed("ui_up"):
			if GameManager:
				GameManager.add_score(10)  # Test score increment
		elif event.is_action_pressed("ui_down"):
			toggle_high_score_visibility(not show_high_score)  # Test visibility toggle
		elif event.is_action_pressed("ui_left"):
			if GameManager:
				GameManager.end_game()  # Test game over
		elif event.is_action_pressed("ui_right"):
			if GameManager:
				GameManager.restart_game()  # Test restart

# GameOverUI.gd - FRESH CLEAN VERSION
extends Control

@onready var final_score_label = $Panel/VBoxContainer/FinalScore
@onready var high_score_label = $Panel/VBoxContainer/HighScore
@onready var new_record_label = $Panel/VBoxContainer/NewRecord
@onready var collectibles_container = $Panel/VBoxContainer/CollectiblesContainer
@onready var retry_button = $Panel/VBoxContainer/HBoxContainer/Retry2
@onready var game_title = $Panel/Control/GameOverTitle
@onready var over_title = $Panel/Control/GameOverTitle2

var auto_restart_timer: float = 3.0
var countdown_label: Label
var is_auto_restarting: bool = false

func _ready():
	# Setup for proper layering and input
	z_index = 1000
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# CRITICAL: Allow processing when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Start hidden
	visible = false

	# Connect retry button
	if retry_button:
		retry_button.pressed.connect(restart_game)
		print("✅ Retry button connected in _ready")

func show_game_over_screen(score: int, is_new_high_score: bool, collectible_stats: Dictionary):
	print("=== Showing Game Over Screen ===")

	# Update score labels
	if final_score_label:
		final_score_label.text = "Score: " + str(score)
	if high_score_label:
		high_score_label.text = "Best: " + str(GameManager.get_high_score())
	if new_record_label:
		new_record_label.visible = is_new_high_score

	# Show collectible stats
	setup_collectible_display(collectible_stats)

	# Add countdown label
	create_countdown_label()

	# Make visible
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE

	# Start neon effect
	call_deferred("start_neon_effect")

	# Start auto-restart countdown
	is_auto_restarting = true
	auto_restart_timer = 3.0
	start_auto_restart_countdown()

func create_countdown_label():
	"""Create countdown display"""
	countdown_label = Label.new()
	#countdown_label.text = "Auto-restart in 3..."
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 18)
	countdown_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))

	# Add to the UI (after collectibles container)
	var vbox = collectibles_container.get_parent()
	vbox.add_child(countdown_label)
	vbox.move_child(countdown_label, vbox.get_child_count() - 2)  # Before retry button

func start_auto_restart_countdown():
	"""Start the 3-second countdown"""
	while auto_restart_timer > 0 and is_auto_restarting:
		#if countdown_label:
			#countdown_label.text = "Auto-restart in " + str(ceil(auto_restart_timer)) + "..."

		await get_tree().create_timer(0.1).timeout
		auto_restart_timer -= 0.1

	# Auto-restart if not manually interrupted
	if is_auto_restarting:
		print("⏰ AUTO-RESTART TRIGGERED!")
		#restart_game()

func setup_collectible_display(stats: Dictionary):
	"""Setup collectible icons and counts"""
	# Clear existing
	for child in collectibles_container.get_children():
		child.queue_free()

	if stats.is_empty():
		var label = Label.new()
		label.text = "No items collected"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		collectibles_container.add_child(label)
		return

	# Set grid columns
	collectibles_container.columns = 6

	# Add each collectible
	for item_name in stats:
		var count = stats[item_name]

		# Container for icon + count
		var item_box = VBoxContainer.new()
		item_box.custom_minimum_size = Vector2(80, 60)
		collectibles_container.add_child(item_box)

		# Icon
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.texture = get_collectible_texture(item_name)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_box.add_child(icon)

		# Count
		var count_label = Label.new()
		count_label.text = "x" + str(count)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_box.add_child(count_label)

func get_collectible_texture(name: String) -> Texture2D:
	"""Get texture for collectible by name"""
	match name:
		"Avocado":
			return preload("res://Assets/Collectibles/avacado.png")
		"Tomato":
			return preload("res://Assets/Collectibles/tomato.png")
		"Strawberry":
			return preload("res://Assets/Collectibles/strawberry.png")
		"Orange":
			return preload("res://Assets/Collectibles/orange.png")
		_:
			return null

func start_neon_effect():
	"""Start the neon flickering effect"""
	if not game_title or not over_title:
		print("⚠️ Neon labels not found")
		return

	print("✨ Starting neon effect")
	neon_cycle()

func neon_cycle():
	"""Neon flicker cycle: Game x2, Over x1, repeat"""
	var dim = Color(0.2, 0.2, 0.2, 1.0)
	var bright = Color.WHITE

	# Game flicker 1
	game_title.modulate = dim
	await get_tree().create_timer(0.1).timeout
	game_title.modulate = bright
	await get_tree().create_timer(0.3).timeout

	# Game flicker 2
	game_title.modulate = dim
	await get_tree().create_timer(0.1).timeout
	game_title.modulate = bright
	await get_tree().create_timer(0.3).timeout

	# Over flicker 1
	over_title.modulate = dim
	await get_tree().create_timer(0.1).timeout
	over_title.modulate = bright

	# Wait and repeat
	await get_tree().create_timer(2.0).timeout
	neon_cycle()

func restart_game():
	"""Restart the game"""
	print("🔥🔥🔥 RESTART FUNCTION CALLED! 🔥🔥🔥")
	visible = false
	GameManager.restart_game()

func _gui_input(event):
	"""Debug mouse clicks on the UI"""
	if event is InputEventMouseButton and event.pressed:
		print("🖱️ Mouse clicked on GameOverUI!")
		# Force restart on any click for now
		restart_game()

func _input(event):
	"""Handle input - spacebar, mobile touch, or any key to restart"""
	if not visible:
		return

	# Spacebar to restart
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		restart_game()
		return

	# Any key to restart (for convenience)
	if event is InputEventKey and event.pressed:
		print("🎮 Key pressed: ", event.keycode, " - Restarting!")
		restart_game()
		return

	# Mobile touch to restart
	if event is InputEventScreenTouch and event.pressed:
		restart_game()

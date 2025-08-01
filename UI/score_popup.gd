# ScorePopup.gd
extends Control

@onready var score_label = $ScoreLabel

# Colors for different states
const NORMAL_COLOR = Color(1.0, 1.0, 0.0, 1.0)      # Yellow
const HIGH_SCORE_COLOR = Color(0.0, 1.0, 0.2, 1.0)  # Bright green
const RECORD_COLOR = Color(1.0, 0.2, 0.9, 1.0)      # Hot pink/magenta

func show_score_popup(score_value: int, current_score: int, high_score: int, world_position: Vector2):
	# Set the score text
	score_label.text = "+" + str(score_value)

	# Determine color based on score status
	var color = NORMAL_COLOR
	if current_score > high_score:
		color = HIGH_SCORE_COLOR
		score_label.text += "!"  # Add excitement
	if current_score == high_score + score_value:  # Just broke the record
		color = RECORD_COLOR
		score_label.text = "NEW RECORD! +" + str(score_value)

	# Set the color - create LabelSettings if it doesn't exist
	if not score_label.label_settings:
		score_label.label_settings = LabelSettings.new()
		score_label.label_settings.font_size = 24
		score_label.label_settings.outline_size = 2
		score_label.label_settings.outline_color = Color.BLACK

	score_label.label_settings.font_color = color

	# Position the popup at Toasty's location
	global_position = world_position - Vector2(50, 30)  # Offset above Toasty

	# Make sure it's visible
	modulate.a = 1.0
	scale = Vector2.ONE

	# Create the animation
	animate_popup()

func animate_popup():
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple animations at once

	# Move upward and fade out
	tween.tween_property(self, "global_position:y", global_position.y - 60, 1.2)
	tween.tween_property(self, "modulate:a  ", 0.0, 1.2)

	# Scale animation - pop in then shrink
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.3).set_delay(0.15)

	# Clean up after animation
	await tween.finished
	queue_free()

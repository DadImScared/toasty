# CatAnnouncement.gd - COMPLETE SEQUENCE VERSION
extends AnimatedSprite2D

signal cat_announcement_finished(announcement_type: String)

func _ready():
	# Test mode for standalone
	if get_tree().current_scene == self or get_tree().current_scene.name == "CatAnnouncement":
		print("🐱 STANDALONE TEST MODE - Starting full sequence")
		await get_tree().process_frame

	# Always do the full sequence
	await do_full_cat_sequence()

func do_full_cat_sequence():
	"""Complete cat announcement sequence: peak -> peak -> peak_higher -> prepare"""
	print("🐱 STARTING FULL CAT SEQUENCE!")

	# 1. Peak from random location
	print("🎬 === PEAK #1 ===")
	await do_peak_sequence()
	await get_tree().create_timer(0.5).timeout  # Brief pause

	# 2. Peak from another random location
	print("🎬 === PEAK #2 ===")
	await do_peak_sequence()
	await get_tree().create_timer(0.5).timeout  # Brief pause

	# 3. Peak higher from right side
	print("🎬 === PEAK HIGHER ===")
	await do_peak_higher_sequence()
	await get_tree().create_timer(0.5).timeout  # Brief pause

	# 4. Prepare from right side (final warning)
	print("🎬 === PREPARE (FINAL WARNING) ===")
	await do_prepare_sequence()

	# Signal that the full sequence is complete - time to spawn the real cat!
	print("🐱 FULL SEQUENCE COMPLETE - SPAWNING ATTACK CAT!")
	cat_announcement_finished.emit("full_sequence")
	# Don't queue_free yet - let the main scene handle spawning the attack
	# The main scene will spawn the attack cat and then we can clean up

func do_peak_sequence():
	"""Single peak sequence: slide in -> animate -> slide out"""
	var edge = choose_random_edge()
	print("🎬 Peak sequence from: ", edge)

	position_off_screen(edge)
	set_rotation_for_edge(edge)

	play("peak")
	await slide_to_peek_position(edge)
	await wait_for_animation_loops(2)  # Shorter for sequence
	await slide_out_of_view(edge)

func do_peak_higher_sequence():
	"""Single peak higher sequence: slide in -> animate -> slide out"""
	print("🎬 Peak higher sequence from right")

	position_off_screen("right")
	rotation_degrees = 270

	play("peak_higher")
	await slide_to_peek_position("right")
	await wait_for_animation_loops(2)
	await slide_out_of_view("right")

func do_prepare_sequence():
	"""Single prepare sequence: slide in -> animate -> slide out"""
	print("🎬 Prepare sequence from right")

	position_off_screen("right")
	rotation_degrees = 270

	play("prepare")
	await slide_to_peek_position("right")
	await wait_for_animation_loops(3)  # Longer for final warning
	await slide_out_of_view("right")

func choose_random_edge() -> String:
	var edges = ["top", "right", "bottom", "left"]
	return edges[randi() % edges.size()]

func position_off_screen(edge: String):
	"""Position cat completely off the specified screen edge"""
	var viewport = get_viewport().get_visible_rect()
	var sprite_size = 64  # Default size

	# Try to get actual sprite size
	if sprite_frames:
		var anim_names = ["peak", "peak_higher", "prepare"]
		for anim_name in anim_names:
			if sprite_frames.has_animation(anim_name):
				var texture = sprite_frames.get_frame_texture(anim_name, 0)
				if texture:
					sprite_size = max(texture.get_width(), texture.get_height())
					break

	match edge:
		"top":
			global_position = Vector2(
				randf_range(100, viewport.size.x - 100),
				-sprite_size
			)
		"right":
			global_position = Vector2(
				viewport.size.x + sprite_size,
				randf_range(100, viewport.size.y - 100)
			)
		"bottom":
			global_position = Vector2(
				randf_range(100, viewport.size.x - 100),
				viewport.size.y + sprite_size
			)
		"left":
			global_position = Vector2(
				-sprite_size,
				randf_range(100, viewport.size.y - 100)
			)

func set_rotation_for_edge(edge: String):
	"""Set rotation so head points into screen"""
	match edge:
		"top":
			rotation_degrees = 180  # Head pointing down
		"right":
			rotation_degrees = 270  # Head pointing left
		"bottom":
			rotation_degrees = 0    # Head pointing up
		"left":
			rotation_degrees = 90   # Head pointing right

func slide_to_peek_position(edge: String):
	"""Slide to sit on the edge of the screen"""
	var viewport = get_viewport().get_visible_rect()
	var edge_distance = 25  # Show a bit more of the cat
	var target = global_position

	match edge:
		"top":
			target.y = edge_distance
		"right":
			target.x = viewport.size.x - edge_distance
		"bottom":
			target.y = viewport.size.y - edge_distance
		"left":
			target.x = edge_distance

	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 1.0)
	await tween.finished

func wait_for_animation_loops(loop_count: int):
	"""Wait for a specific amount of time instead of counting loops"""
	var wait_time = 2.0 * loop_count  # 2 seconds per loop
	await get_tree().create_timer(wait_time).timeout

func slide_out_of_view(edge: String):
	"""Slide back off-screen completely"""
	stop()  # Stop animation

	var viewport = get_viewport().get_visible_rect()
	var sprite_size = 64

	if sprite_frames:
		var anim_names = ["peak", "peak_higher", "prepare"]
		for anim_name in anim_names:
			if sprite_frames.has_animation(anim_name):
				var texture = sprite_frames.get_frame_texture(anim_name, 0)
				if texture:
					sprite_size = max(texture.get_width(), texture.get_height())
					break

	var target = global_position

	match edge:
		"top":
			target.y = -sprite_size
		"right":
			target.x = viewport.size.x + sprite_size
		"bottom":
			target.y = viewport.size.y + sprite_size
		"left":
			target.x = -sprite_size

	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 1.2)  # Slower slide out
	await tween.finished

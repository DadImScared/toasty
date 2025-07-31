# CollectibleItem.gd
extends Area2D

@export var collectible_data: Collectible
@onready var sprite = $AnimatedSprite2D
@onready var audio_player = $AudioStreamPlayer2D

signal collected(collectible: Collectible)

var outline_sprite  # Keep reference to clean it up

func _ready():
	add_to_group("scrolling_objects")
	if collectible_data:
		setup_collectible()

	# Add visual effects
	add_glow_effect()
	create_wiggle_animation()

	# Connect collection signal
	body_entered.connect(_on_body_entered)

func setup_collectible():
	# Set up sprite
	if collectible_data.texture:
		sprite.texture = collectible_data.texture

	sprite.scale = Vector2(collectible_data.scale, collectible_data.scale)

	# Set up audio
	if collectible_data.sound_effect:
		audio_player.stream = collectible_data.sound_effect

func add_glow_effect():
	# Create a subtle white glow instead of yellow outline
	outline_sprite = sprite.duplicate()
	add_child(outline_sprite)
	move_child(outline_sprite, 0)  # Put behind main sprite

	# Make it slightly bigger with white glow
	outline_sprite.scale = sprite.scale * 1.15  # Smaller outline
	outline_sprite.modulate = Color(1.0, 1.0, 1.0, 0.4)  # White, semi-transparent
	outline_sprite.z_index = sprite.z_index - 1

	# Subtle glow pulse
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(outline_sprite, "modulate:a", 0.2, 1.5)  # Gentle fade
	glow_tween.tween_property(outline_sprite, "modulate:a", 0.6, 1.5)  # Gentle brighten

func create_wiggle_animation():
	# Gentle wiggle rotation
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(sprite, "rotation", deg_to_rad(8), 0.8)   # Smaller angle
	rotation_tween.tween_property(sprite, "rotation", deg_to_rad(-8), 0.8)

	# Subtle scale pulse
	var scale_tween = create_tween()
	scale_tween.set_loops()
	var original_scale = sprite.scale
	scale_tween.tween_property(sprite, "scale", original_scale * 1.05, 1.0)  # Smaller pulse
	scale_tween.tween_property(sprite, "scale", original_scale, 1.0)

func _on_body_entered(body):
	if body.name == "Toasty":
		collect()

func collect():
	# Create collection particles
	create_collection_particles()

	# Hide BOTH sprites immediately to fix the faded visual bug
	sprite.visible = false
	if outline_sprite:
		outline_sprite.visible = false

	# Disable collision
	set_collision_layer_value(1, false)

	# Emit signal with collectible data
	collected.emit(collectible_data)

	# Play sound
	if audio_player.stream:
		audio_player.play()
		await audio_player.finished
	else:
		await get_tree().create_timer(0.5).timeout

	queue_free()

func create_collection_particles():
	var particles = CPUParticles2D.new()
	add_child(particles)

	# Configure particles
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.6
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 0.8
	particles.color = collectible_data.particle_color if collectible_data else Color.YELLOW

	# Create simple particle texture
	var texture = ImageTexture.new()
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	texture.set_image(image)
	particles.texture = texture

	# Burst pattern
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.direction = Vector2(0, -1)
	particles.spread = 50.0
	particles.gravity = Vector2(0, 80)

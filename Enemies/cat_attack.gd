# CatAttack.gd - Attach to Area2D root node
extends Area2D

signal hit_player

@export var attack_speed: float = 350.0
var attack_direction: Vector2
var is_attacking: bool = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Connect collision detection
	body_entered.connect(_on_body_entered)

	# Start the attack
	start_attack()

func start_attack():
	"""Start the cat attack from screen edge"""
	choose_attack_direction()
	position_at_spawn_point()
	set_attack_rotation()

	# Play attack animation
	if animated_sprite:
		animated_sprite.play("attack")  # Assuming you have an "attack" animation

	# Start moving
	is_attacking = true
	print("🐱 CAT ATTACK STARTED! Direction: ", attack_direction)

func choose_attack_direction():
	"""Choose attack direction - only from the right side"""
	# Always attack from the right side only
	attack_direction = Vector2.LEFT  # Moving left (coming from right)
	print("🎬 Attacking from RIGHT side, moving LEFT")

func position_at_spawn_point():
	"""Position cat at random height on the right edge of screen"""
	var viewport = get_viewport().get_visible_rect()

	# Random Y position instead of targeting Toasty
	var random_y = randf_range(100, viewport.size.y - 100)

	# Always spawn from the right side at random height
	global_position = Vector2(viewport.size.x + 100, random_y)
	print("🎬 Spawning RIGHT of screen at random Y: ", global_position)

func set_attack_rotation():
	"""Set cat to face left (attacking from right side)"""
	if animated_sprite:
		animated_sprite.flip_h = true  # Face left
		rotation_degrees = 0

func _physics_process(delta):
	if is_attacking:
		# Move in attack direction
		global_position += attack_direction * attack_speed * delta

		# Check if cat has gone off-screen (missed the player)
		var viewport = get_viewport().get_visible_rect()
		var buffer = 200

		if (global_position.x < -buffer or
			global_position.x > viewport.size.x + buffer or
			global_position.y > viewport.size.y + buffer):

			print("🐱 Cat attack missed - cleaning up")
			queue_free()

func _on_body_entered(body):
	if body.name == "Toasty":
		print("🐱 CAT HIT TOASTY!")
		hit_player.emit()

		# Optional: Add hit effect/animation here

		# Clean up
		is_attacking = false
		queue_free()

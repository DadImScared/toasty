extends CharacterBody2D

@export var jump_force = -300
@export var gravity = 400
@export var max_fall_speed = 200
@export var air_resistance = 0.98

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	velocity.y += gravity * delta
	velocity.y *= air_resistance
	velocity.y = min(velocity.y, max_fall_speed)

	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

	move_and_slide()
	update_animation()

func update_animation():
	if velocity.y < -50:
		animated_sprite.play("jump")
	elif velocity.y > 50:
		animated_sprite.play("fall")
	else:
		animated_sprite.play("jump")

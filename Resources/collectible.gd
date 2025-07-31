# Collectible.gd - Save as a script file
extends Resource
class_name Collectible

@export var name: String = "Collectible"
@export var value: int = 10
@export var texture: Texture2D
@export var sound_effect: AudioStream
@export var particle_color: Color = Color.YELLOW
@export var scale: float = 1.0
@export var animation_speed: float = 1.0

# Special effects when collected
@export var gives_speed_boost: bool = false
@export var gives_extra_jump: bool = false
@export var boost_duration: float = 2.0

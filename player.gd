extends CharacterBody2D

const RUN_SPEED := 220.0
const ACCEL := 900.0
const FRICTION := 1200.0
const JUMP_VELOCITY := -420.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing := "right"
var landing := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var dir := Input.get_axis("left", "right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * RUN_SPEED, ACCEL * delta)
		facing = "right" if dir > 0.0 else "left"
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and not was_on_floor:
		landing = true

	_update_animation(dir)


func _update_animation(dir: float) -> void:
	if not is_on_floor():
		landing = false
		_play("jump" if velocity.y < 0.0 else "fall")
	elif landing:
		_play("land")
		if dir != 0.0 or not sprite.is_playing():
			landing = false
	elif absf(velocity.x) > 10.0:
		_play("run" if absf(velocity.x) > RUN_SPEED * 0.6 else "walk")
	else:
		_play("idle")


func _play(anim: String) -> void:
	var full := anim + "_" + facing
	if sprite.animation != full:
		sprite.play(full)

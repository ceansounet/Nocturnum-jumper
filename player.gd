extends CharacterBody2D

# ---- movement
const RUN_SPEED := 220.0
const ACCEL := 900.0
const FRICTION := 1200.0
const JUMP_VELOCITY := -420.0
const DOUBLE_JUMP_VELOCITY := -380.0

# ---- leniency
const COYOTE_TIME := 0.12  # seconds you can still jump after leaving a ledge
const JUMP_BUFFER := 0.10  # a jump pressed just before landing still counts

# ---- dash
const DASH_SPEED := 360.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.30

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing := "right"
var landing := false

var has_double_jump := false  # switched on by the boots pickup
var items := {}               # inventory: "iron_key", "gold_key", ...
var air_jumps_left := 0
var coyote := 0.0
var jump_buffer := 0.0

var dash_timer := 0.0
var dash_cd := 0.0
var dash_dir := 1.0
var air_dash_used := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# creates these inputs if you haven't added them in the Input Map
	_ensure_action("dash", [KEY_SHIFT, KEY_X])
	_ensure_action("interact", [KEY_E])


func _ensure_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func give_double_jump() -> void:
	has_double_jump = true


# ---- inventory (used by keys, chests and doors)
func give_item(id: String) -> void:
	items[id] = true


func has_item(id: String) -> bool:
	return items.has(id)


func take_item(id: String) -> void:
	items.erase(id)


## Shows an item icon floating above the head for a few seconds.
func show_item_icon(tex: Texture2D, seconds := 2.5) -> void:
	var icon := Sprite2D.new()
	icon.texture = tex
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.z_index = 10
	icon.position = Vector2(0, -42)  # the player's origin is at his feet
	icon.scale = Vector2.ZERO
	add_child(icon)

	var pop := icon.create_tween()
	pop.tween_property(icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_interval(seconds)
	pop.tween_property(icon, "modulate:a", 0.0, 0.5)
	pop.tween_callback(icon.queue_free)

	var rise := icon.create_tween()
	rise.tween_property(icon, "position:y", -52.0, seconds + 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("left", "right")
	if dir != 0.0:
		facing = "right" if dir > 0.0 else "left"

	dash_cd = maxf(dash_cd - delta, 0.0)

	# refill everything when standing on the ground
	if is_on_floor():
		coyote = COYOTE_TIME
		air_jumps_left = 1 if has_double_jump else 0
		air_dash_used = false
	else:
		coyote -= delta

	var jump_pressed := Input.is_action_just_pressed("jump")
	if jump_pressed:
		jump_buffer = JUMP_BUFFER
	else:
		jump_buffer -= delta

	# start a dash (once per air time, freely on the ground)
	if Input.is_action_just_pressed("dash") and dash_timer <= 0.0 and dash_cd <= 0.0 \
			and (is_on_floor() or not air_dash_used):
		dash_timer = DASH_TIME
		dash_cd = DASH_COOLDOWN
		dash_dir = 1.0 if facing == "right" else -1.0
		if not is_on_floor():
			air_dash_used = true
		landing = false

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
		if dash_timer <= 0.0:  # snap back to normal speed when the dash ends
			velocity.x = clampf(velocity.x, -RUN_SPEED, RUN_SPEED)
	else:
		if not is_on_floor():
			velocity.y += gravity * delta

		if jump_buffer > 0.0 and coyote > 0.0:
			# normal jump (also works for a moment after leaving a ledge)
			velocity.y = JUMP_VELOCITY
			jump_buffer = 0.0
			coyote = 0.0
		elif jump_pressed and air_jumps_left > 0:
			# double jump, only with the boots
			velocity.y = DOUBLE_JUMP_VELOCITY
			air_jumps_left -= 1
			jump_buffer = 0.0

		if dir != 0.0:
			velocity.x = move_toward(velocity.x, dir * RUN_SPEED, ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and not was_on_floor and dash_timer <= 0.0:
		landing = true

	_update_animation(dir)


func _update_animation(dir: float) -> void:
	if dash_timer > 0.0:
		landing = false
		_play("dash")
	elif not is_on_floor():
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
	if sprite.animation != full \
			or (not sprite.is_playing() and sprite.sprite_frames.get_animation_loop(full)):
		sprite.play(full)

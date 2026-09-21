extends Area2D

@export var required_item := "gold_key"
## true = opens as soon as you touch it holding the key. false = press E (interact).
@export var auto_open := true
@export var end_screen_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var unlock_sound: AudioStreamPlayer = $UnlockSound
@onready var open_sound: AudioStreamPlayer = $OpenSound
@onready var locked_sound: AudioStreamPlayer = $LockedSound

var _player: CharacterBody2D
var _busy := false
var _warned := false
var _shake: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("has_item"):
		_player = body
		_warned = false


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null


func _physics_process(_delta: float) -> void:
	if _busy or _player == null or not _player.is_on_floor():
		return
	var interact := InputMap.has_action("interact") and Input.is_action_just_pressed("interact")
	if not (auto_open or interact):
		return
	if _player.has_item(required_item):
		_open(_player)
	elif interact or not _warned:
		_warned = true
		locked_sound.play()
		if _shake:
			_shake.kill()
		_shake = sprite.create_tween()
		for dx in [2.0, -2.0, 1.0, -1.0, 0.0]:
			_shake.tween_property(sprite, "position:x", dx, 0.04)


func _open(player: CharacterBody2D) -> void:
	_busy = true
	player.take_item(required_item)  # the gold key is used up

	# take control away from the player
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	var spr := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var facing: String = str(player.get("facing")) if "facing" in player else "right"
	if spr:
		spr.play("idle_" + facing)

	unlock_sound.play()
	await get_tree().create_timer(0.55).timeout

	# the door swings open
	open_sound.play()
	for f in [1, 2, 3]:
		sprite.frame = f
		await get_tree().create_timer(0.22).timeout

	# the player walks to the middle of the doorway and turns his back to us
	var dx := global_position.x - player.global_position.x
	if spr and absf(dx) > 1.0:
		spr.play("walk_" + ("right" if dx > 0.0 else "left"))
		var walk := create_tween()
		walk.tween_property(player, "global_position:x", global_position.x, maxf(0.3, absf(dx) / 70.0))
		await walk.finished
	if spr:
		spr.play("idle_back")
	await get_tree().create_timer(0.6).timeout

	# the player fades to black as he steps into the doorway
	if spr:
		var fade := spr.create_tween().set_parallel(true)
		fade.tween_property(spr, "modulate", Color.BLACK, 1.0)
		fade.tween_property(spr, "scale", Vector2(0.85, 0.85), 1.0)
		fade.tween_property(spr, "position:y", spr.position.y + 3.0, 1.0)
		await fade.finished

	# then the whole screen fades to black and the end screen appears
	if end_screen_scene:
		var end := end_screen_scene.instantiate()
		var host: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
		host.add_child(end)
		end.play()

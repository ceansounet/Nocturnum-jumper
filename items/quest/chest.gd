extends Area2D

@export var required_item := "iron_key"
@export var reward_item := "gold_key"
## true = opens as soon as you touch it holding the key. false = press E (interact).
@export var auto_open := true
@export var show_time := 2.5  ## seconds the reward floats above the player's head

@onready var sprite: Sprite2D = $Sprite2D
@onready var reward_sprite: Sprite2D = $RewardKey
@onready var unlock_sound: AudioStreamPlayer = $UnlockSound
@onready var open_sound: AudioStreamPlayer = $OpenSound
@onready var reward_sound: AudioStreamPlayer = $RewardSound
@onready var locked_sound: AudioStreamPlayer = $LockedSound

var _player: CharacterBody2D
var _opened := false
var _busy := false
var _warned := false
var _shake: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	reward_sprite.hide()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("has_item"):
		_player = body
		_warned = false


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null


func _physics_process(_delta: float) -> void:
	if _opened or _busy or _player == null or not _player.is_on_floor():
		return
	var interact := InputMap.has_action("interact") and Input.is_action_just_pressed("interact")
	if not (auto_open or interact):
		return
	if _player.has_item(required_item):
		_open(_player)
	elif interact or not _warned:
		_warned = true
		_locked_feedback()


func _locked_feedback() -> void:
	locked_sound.play()
	if _shake:
		_shake.kill()
	_shake = sprite.create_tween()
	for dx in [3.0, -3.0, 2.0, -2.0, 0.0]:
		_shake.tween_property(sprite, "position:x", dx, 0.04)


func _open(player: CharacterBody2D) -> void:
	_busy = true
	player.take_item(required_item)  # the iron key is used up
	unlock_sound.play()
	await get_tree().create_timer(0.45).timeout

	open_sound.play()
	for f in [1, 2]:
		sprite.frame = f
		await get_tree().create_timer(0.16).timeout
	_opened = true
	set_deferred("monitoring", false)

	# the gold key rises out of the chest ...
	reward_sprite.position = Vector2(0, -14)
	reward_sprite.modulate.a = 1.0
	reward_sprite.show()
	var rise := reward_sprite.create_tween().set_parallel(true)
	rise.tween_property(reward_sprite, "position:y", -40.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rise.tween_property(reward_sprite, "modulate:a", 0.0, 0.5).set_delay(0.35)

	# ... and ends up in the player's inventory, floating above his head
	reward_sound.play()
	player.give_item(reward_item)
	if player.has_method("show_item_icon"):
		player.show_item_icon(reward_sprite.texture, show_time)
	_busy = false

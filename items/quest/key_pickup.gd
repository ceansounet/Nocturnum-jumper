extends Area2D

@export var item_id := "iron_key"
@export var show_time := 2.5  ## seconds the key floats above the player's head

@onready var sprite: Sprite2D = $Sprite2D
@onready var sound: AudioStreamPlayer = $Sound

var _taken := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# gentle hover so the key is easy to spot
	var hover := sprite.create_tween().set_loops()
	hover.tween_property(sprite, "position:y", -3.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover.tween_property(sprite, "position:y", 3.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.has_method("give_item"):
		return
	_taken = true
	body.give_item(item_id)
	if body.has_method("show_item_icon"):
		body.show_item_icon(sprite.texture, show_time)

	sprite.hide()
	set_deferred("monitoring", false)
	sound.play()
	await sound.finished  # keep this node alive until the sound is done
	queue_free()

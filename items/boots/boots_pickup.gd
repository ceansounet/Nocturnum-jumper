extends Area2D

@export var show_time := 2.5  ## seconds the boots float above the player's head

@onready var sprite: Sprite2D = $Sprite2D
@onready var sound: AudioStreamPlayer = $Sound

var _taken := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# gentle hover so the item is easy to spot
	var hover := sprite.create_tween().set_loops()
	hover.tween_property(sprite, "position:y", -3.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover.tween_property(sprite, "position:y", 3.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.has_method("give_double_jump"):
		return
	_taken = true
	body.give_double_jump()
	_show_on_head(body)

	sprite.hide()
	set_deferred("monitoring", false)
	sound.play()
	await sound.finished  # keep this node alive until the sound is done
	queue_free()


func _show_on_head(body: Node2D) -> void:
	var icon := Sprite2D.new()
	icon.texture = sprite.texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.z_index = 10
	icon.position = Vector2(0, -42)  # player origin is at his feet
	icon.scale = Vector2.ZERO
	body.add_child(icon)

	# pop in, stay a moment, fade out, disappear
	var pop := icon.create_tween()
	pop.tween_property(icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_interval(show_time)
	pop.tween_property(icon, "modulate:a", 0.0, 0.5)
	pop.tween_callback(icon.queue_free)

	# slow float upwards the whole time
	var rise := icon.create_tween()
	rise.tween_property(icon, "position:y", -52.0, show_time + 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

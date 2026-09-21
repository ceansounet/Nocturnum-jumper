extends Area2D
## false = the player keeps moving (falling, sliding) while the screen fades
@export var freeze_player := false
@export var spawn_point: Marker2D
@export var fade_time := 0.4
## Plays the "death" sprite animation before fading. Leave off for pits.
@export var play_death_animation := false
## Scene the "Give up" button goes to. Empty = quit the game.
@export_file("*.tscn") var menu_scene := ""

var _layer: CanvasLayer
var _fade: ColorRect
var _menu: VBoxContainer
var _respawn_btn: Button
var _spawn_pos := Vector2.ZERO
var _player: CharacterBody2D
var _dying := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_ui()
	if spawn_point:
		_spawn_pos = spawn_point.global_position
	else:
		var p := get_tree().current_scene.find_child("Player", true, false) as Node2D
		if p:
			_spawn_pos = p.global_position


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS  # keeps working while the game is paused
	add_child(_layer)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	_menu.visible = false
	center.add_child(_menu)

	var title := Label.new()
	title.text = "You died"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(title)

	_respawn_btn = Button.new()
	_respawn_btn.text = "Respawn"
	_respawn_btn.custom_minimum_size = Vector2(200, 44)
	_respawn_btn.pressed.connect(_on_respawn)
	_menu.add_child(_respawn_btn)

	var give_up := Button.new()
	give_up.text = "Give up"
	give_up.custom_minimum_size = Vector2(200, 44)
	give_up.pressed.connect(_on_give_up)
	_menu.add_child(give_up)

func _on_body_entered(body: Node2D) -> void:
	if _dying or not body is CharacterBody2D:
		return
	_dying = true
	_player = body

	if freeze_player:
		_player.velocity = Vector2.ZERO
		_player.set_physics_process(false)
		var spr := _player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr:
			if play_death_animation:
				var facing: String = str(_player.get("facing")) if "facing" in _player else "right"
				spr.play("death_" + facing)
				await get_tree().create_timer(0.6).timeout
			else:
				spr.stop()

	var tw := _layer.create_tween()
	tw.tween_property(_fade, "color:a", 1.0, fade_time)
	await tw.finished

	get_tree().paused = true
	_menu.visible = true
	_respawn_btn.grab_focus()

func _on_respawn() -> void:
	_menu.visible = false
	get_tree().paused = false
	_player.global_position = _spawn_pos
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(true)

	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.reset_smoothing()  # no camera glide from the death spot

	var tw := _layer.create_tween()
	tw.tween_property(_fade, "color:a", 0.0, fade_time)
	await tw.finished
	_dying = false


func _on_give_up() -> void:
	get_tree().paused = false
	if menu_scene != "":
		get_tree().change_scene_to_file(menu_scene)
	else:
		get_tree().quit()

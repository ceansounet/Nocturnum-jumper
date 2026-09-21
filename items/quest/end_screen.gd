extends CanvasLayer

@export var fade_time := 1.2       ## screen fading to black
@export var text_fade_time := 1.0  ## title and buttons fading in

@onready var background: ColorRect = $Background
@onready var content: Control = $Center
@onready var play_again: Button = $Center/Box/PlayAgain
@onready var quit_button: Button = $Center/Box/Quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps working while the game is paused
	background.color.a = 0.0
	content.modulate.a = 0.0
	content.hide()
	play_again.pressed.connect(_on_play_again)
	quit_button.pressed.connect(_on_quit)


## Fade to black, then show the end screen.
func play() -> void:
	var tw := create_tween()
	tw.tween_property(background, "color:a", 1.0, fade_time)
	await tw.finished
	get_tree().paused = true  # the world is hidden now, so freeze it

	content.show()
	var tw2 := create_tween()
	tw2.tween_property(content, "modulate:a", 1.0, text_fade_time)
	await tw2.finished
	play_again.grab_focus()  # keyboard / gamepad friendly


func _on_play_again() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().quit()

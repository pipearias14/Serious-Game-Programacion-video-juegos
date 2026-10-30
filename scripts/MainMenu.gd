extends Node2D
## Menú de inicio. "JUGAR" empieza un ciclo nuevo: test inicial -> juego -> test final.

@onready var play_button: Button = %PlayButton
@onready var how_button: Button = %HowButton
@onready var quit_button: Button = %QuitButton
@onready var close_button: Button = %CloseButton
@onready var main_box: Node2D = %MainGroup
@onready var how_panel: Node2D = %HowToGroup
@onready var title: Label = %Title


func _ready() -> void:
	GameManager.play_music("menu")
	play_button.pressed.connect(_on_play_pressed)
	how_button.pressed.connect(_show_how_to.bind(true))
	close_button.pressed.connect(_show_how_to.bind(false))
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("web")
	_show_how_to(false)

	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "modulate", Color(0.6, 1.0, 0.9), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and how_panel.visible:
		_show_how_to(false)


func _show_how_to(open: bool) -> void:
	how_panel.visible = open
	main_box.visible = not open
	if open:
		close_button.grab_focus()
	else:
		play_button.grab_focus()


func _on_play_pressed() -> void:
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Trivia.tscn")

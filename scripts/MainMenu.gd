extends Node2D
## Menú de inicio. "JUGAR" empieza un ciclo nuevo: test inicial -> juego -> test final.
## "ÁLBUM" muestra las fichas de hardware y malware desbloqueadas jugando.

const UIKit := preload("res://scripts/UIKit.gd")
const LearnData := preload("res://scripts/LearnData.gd")

@onready var play_button: Button = %PlayButton
@onready var how_button: Button = %HowButton
@onready var quit_button: Button = %QuitButton
@onready var close_button: Button = %CloseButton
@onready var main_box: Node2D = %MainGroup
@onready var how_panel: Node2D = %HowToGroup
@onready var title: Label = %Title

var album_button: Button
var _album: Control
var _album_detail: PanelContainer
var _album_close: Button


func _ready() -> void:
	GameManager.play_music("menu")
	play_button.pressed.connect(_on_play_pressed)
	how_button.pressed.connect(_show_how_to.bind(true))
	close_button.pressed.connect(_show_how_to.bind(false))
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("web")
	_create_album_button()
	_show_how_to(false)

	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "modulate", Color(0.6, 1.0, 0.9), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _album:
			_close_album()
		elif how_panel.visible:
			_show_how_to(false)


# ---------------------------------------------------------------- Álbum
## El botón se crea copiando el estilo de "CÓMO JUGAR" y se reordena la columna.
func _create_album_button() -> void:
	album_button = how_button.duplicate(Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS) as Button
	album_button.unique_name_in_owner = false
	album_button.name = "AlbumButton"
	album_button.text = "ÁLBUM (%d/%d)" % [_unlocked_count(), LearnData.ORDER.size()]
	how_button.get_parent().add_child(album_button)
	album_button.pressed.connect(_open_album)
	var y := 160.0
	for b in [play_button, how_button, album_button, quit_button]:
		b.position.y = y
		b.size.y = 28
		y += 34.0


func _unlocked_count() -> int:
	var n := 0
	for id in LearnData.ORDER:
		if GameManager.album.has(id):
			n += 1
	return n


func _open_album() -> void:
	main_box.visible = false
	_album = Control.new()
	_album.size = Vector2(640, 360)
	add_child(_album)

	var frame := UIKit.panel(UIKit.BLUE, 10.0)
	frame.position = Vector2(30, 16)
	frame.custom_minimum_size = Vector2(580, 328)
	_album.add_child(frame)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	frame.add_child(layout)

	var head := UIKit.label("ÁLBUM DE FICHAS   %d / %d" % [_unlocked_count(), LearnData.ORDER.size()], 18, UIKit.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(head)
	var hint := UIKit.label("Recoge piezas y elimina virus para desbloquear fichas.", 10, UIKit.CYAN)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hint)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)
	var first: Button = null
	for id in LearnData.ORDER:
		var unlocked: bool = GameManager.album.has(id)
		var b := UIKit.button("" if unlocked else "?", 18)
		b.custom_minimum_size = Vector2(58, 58)
		if unlocked:
			b.icon = load("res://assets/sprites/%s.png" % LearnData.CARDS[id]["icon"]) as Texture2D
			b.expand_icon = true
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.focus_entered.connect(_show_album_card.bind(id))
		b.mouse_entered.connect(_show_album_card.bind(id))
		grid.add_child(b)
		if first == null:
			first = b

	_album_detail = UIKit.panel(UIKit.GREY, 8.0)
	_album_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_album_detail)

	_album_close = UIKit.button("VOLVER", 14)
	_album_close.custom_minimum_size = Vector2(160, 26)
	_album_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_album_close.pressed.connect(_close_album)
	layout.add_child(_album_close)

	first.grab_focus()
	_show_album_card(LearnData.ORDER[0])


func _show_album_card(card_id: String) -> void:
	for child in _album_detail.get_children():
		child.queue_free()
	if GameManager.album.has(card_id):
		_album_detail.add_child(UIKit.card_body(card_id, 330.0))
	else:
		var group: String = LearnData.CARDS[card_id]["group"]
		var locked := UIKit.label("FICHA BLOQUEADA\n\n%s" % (
			"Recoge esta pieza en el juego para desbloquearla." if group == "HARDWARE"
			else "Elimina este malware en el juego para desbloquearla."), 11, UIKit.GREY, true)
		locked.custom_minimum_size = Vector2(330, 0)
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_album_detail.add_child(locked)


func _close_album() -> void:
	if _album:
		_album.queue_free()
		_album = null
	main_box.visible = true
	album_button.grab_focus()


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

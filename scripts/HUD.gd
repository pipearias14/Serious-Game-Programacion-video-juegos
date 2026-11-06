extends CanvasLayer
## Interfaz: misión activa, inventario agrupado ("RAM x2"), vidas, nivel,
## barra del jefe, mensajes y pantallas de victoria / game over.

const UIKit := preload("res://scripts/UIKit.gd")

const PART_NAMES := {"BOARD": "Placa base", "CPU": "Procesador", "RAM": "Memoria RAM", "DISK": "Disco"}
## Pista cuando el jugador elige una pieza fuera de orden (según la que tocaba).
const ASSEMBLY_HINTS := {
	"BOARD": "Primero va la PLACA BASE: es la base donde se conecta todo lo demás.",
	"CPU": "Ahora el PROCESADOR: va en su zócalo de la placa, antes que la RAM.",
	"RAM": "Ahora la RAM: se inserta en las ranuras junto al procesador.",
	"DISK": "Al final el DISCO: se conecta a la placa por cable SATA o en la ranura M.2.",
}
const CARD_TIME := 7.0

@onready var mission_title: Label = %MissionTitle
@onready var mission_needs: Label = %MissionNeeds
@onready var level_label: Label = %LevelLabel
@onready var kills_label: Label = %KillsLabel
@onready var hearts_row: HBoxContainer = %HeartsRow
@onready var toast: Label = %Toast
@onready var inventory_list: VBoxContainer = %InventoryList
@onready var boss_box: Control = %BossBox
@onready var boss_bar: ProgressBar = %BossBar
@onready var victory: Control = %Victory
@onready var victory_label: Label = %VictoryLabel
@onready var game_over: Control = %GameOver

var _needs: Dictionary = {}
var _inventory: Array = []
var _toast_tween: Tween
var _heart_full: Texture2D
var _heart_empty: Texture2D

# Fichas educativas (cola: se muestran de una en una sin pausar el juego).
var _card_queue: Array = []
var _card_panel: PanelContainer

# Mesa de ensamblaje.
var _asm_root: Control
var _asm_steps: Array = []
var _asm_index := 0
var _asm_errors := 0
var _asm_on_done: Callable
var _asm_buttons: Array = []
var _asm_options: Array = []
var _asm_progress: HBoxContainer
var _asm_feedback: Label
var _asm_ready_at := 0


func _ready() -> void:
	# Sigue funcionando con el juego en pausa (mesa de ensamblaje).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_heart_full = load("res://assets/sprites/heart.png") as Texture2D
	_heart_empty = load("res://assets/sprites/heart_empty.png") as Texture2D
	toast.modulate.a = 0.0
	victory.visible = false
	game_over.visible = false
	boss_box.visible = false
	update_inventory([])
	set_lives(3, 3)
	set_level(1)
	set_kills(0)


# ---------------------------------------------------------------- Señales del Workbench
func on_mission_changed(_index: int, title: String, needs: Dictionary) -> void:
	mission_title.text = title
	_needs = needs
	_refresh_mission_text()


func on_missing_items(text: String) -> void:
	show_message(text, 3.0)


# ---------------------------------------------------------------- API pública
func update_inventory(inventory: Array) -> void:
	_inventory = inventory.duplicate()
	for child in inventory_list.get_children():
		inventory_list.remove_child(child)
		child.queue_free()

	var counts := {}
	for item_type in _inventory:
		counts[item_type] = int(counts.get(item_type, 0)) + 1

	if counts.is_empty():
		inventory_list.add_child(_make_text_row("(vacío)"))
	else:
		for item_type in GameManager.ITEM_TYPES: # orden estable
			if counts.has(item_type):
				inventory_list.add_child(_make_row(item_type, int(counts[item_type])))
	_refresh_mission_text()


func set_lives(lives: int, max_lives: int) -> void:
	for child in hearts_row.get_children():
		hearts_row.remove_child(child)
		child.queue_free()
	for i in max_lives:
		var icon := TextureRect.new()
		icon.texture = _heart_full if i < lives else _heart_empty
		icon.custom_minimum_size = Vector2(16, 16)
		hearts_row.add_child(icon)


func set_level(level: int) -> void:
	level_label.text = "NIVEL %d" % level


func set_kills(kills: int) -> void:
	kills_label.text = "Virus: %d" % kills


## Sustituye el texto de la misión (p. ej. para el objetivo final).
func set_objective(title: String, text: String) -> void:
	_needs = {}
	mission_title.text = title
	mission_needs.text = text


func show_message(text: String, duration: float = 2.5) -> void:
	toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.5)


func show_boss_bar(maximum: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = maximum
	boss_box.visible = true


func update_boss(current: int, maximum: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current


func hide_boss_bar() -> void:
	boss_box.visible = false


func show_victory(kills: int) -> void:
	hide_boss_bar()
	victory_label.text = "¡SISTEMA LIBERADO!\n\nDerrotaste al REY RANSOMWARE\ny ensamblaste todas las PCs.\n\nVirus eliminados: %d\n\nENTER: test final   R: repetir   ESC: menú" % kills
	victory.visible = true


func show_game_over() -> void:
	hide_boss_bar()
	game_over.visible = true


# ---------------------------------------------------------------- Fichas educativas
## Muestra una ficha a la derecha de la pantalla. No pausa el juego.
func show_card(card_id: String, is_new: bool) -> void:
	_card_queue.append([card_id, is_new])
	if _card_panel == null:
		_next_card()


func _next_card() -> void:
	if _card_queue.is_empty():
		return
	var entry: Array = _card_queue.pop_front()
	var malware: bool = UIKit.LearnData.CARDS[entry[0]]["group"] == "MALWARE"
	_card_panel = UIKit.panel(UIKit.RED if malware else UIKit.GREEN, 6.0)
	_card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_panel.add_child(UIKit.card_body(entry[0], 190.0, entry[1]))
	$Root.add_child(_card_panel)
	_card_panel.reset_size()
	var target := Vector2(640 - _card_panel.size.x - 8, 82)
	var hidden := target + Vector2(230, 0)
	_card_panel.position = hidden
	var tween := _card_panel.create_tween()
	tween.tween_property(_card_panel, "position", target, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(CARD_TIME)
	tween.tween_property(_card_panel, "position", hidden, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_close_card)
	GameManager.play_sfx("success", -14.0)


func _close_card() -> void:
	if _card_panel:
		_card_panel.queue_free()
		_card_panel = null
	_next_card()


# ---------------------------------------------------------------- Mesa de ensamblaje
## Abre la mesa: el jugador debe montar las piezas en orden. Pausa el juego.
## `steps`: [{"type": "BOARD", "count": 1}, ...] en el orden correcto.
## Al terminar llama a `on_done(errores)`.
func open_assembly(title: String, steps: Array, on_done: Callable) -> void:
	_asm_steps = steps
	_asm_index = 0
	_asm_errors = 0
	_asm_on_done = on_done
	_asm_ready_at = Time.get_ticks_msec() + 350 # evita pulsaciones accidentales
	get_tree().paused = true

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_asm_root = dim
	$Root.add_child(_asm_root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_asm_root.add_child(center)
	var panel := UIKit.panel(UIKit.GOLD, 10.0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(400, 0)
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var head := UIKit.label("MESA DE ENSAMBLAJE: " + title, 14, UIKit.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var info := UIKit.label("Monta las piezas en el ORDEN correcto.  Teclas 1-%d o clic." % steps.size(), 10, UIKit.CYAN)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	var prog_row := HBoxContainer.new()
	prog_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prog_row.add_theme_constant_override("separation", 6)
	prog_row.add_child(UIKit.label("Montado:", 10, UIKit.GREY))
	_asm_progress = HBoxContainer.new()
	_asm_progress.add_theme_constant_override("separation", 4)
	prog_row.add_child(_asm_progress)
	box.add_child(prog_row)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	_asm_options = steps.duplicate()
	_asm_options.shuffle()
	_asm_buttons = []
	for i in _asm_options.size():
		var step: Dictionary = _asm_options[i]
		var count: int = step["count"]
		var b := UIKit.button("%d) %s%s" % [i + 1, PART_NAMES[step["type"]], (" x%d" % count) if count > 1 else ""], 10)
		b.icon = GameManager.item_texture(step["type"])
		b.custom_minimum_size = Vector2(0, 30)
		b.pressed.connect(_on_assembly_choice.bind(i))
		buttons.add_child(b)
		_asm_buttons.append(b)

	_asm_feedback = UIKit.label("¿Qué pieza va primero?", 10, Color.WHITE, true)
	_asm_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_asm_feedback.custom_minimum_size = Vector2(400, 28)
	box.add_child(_asm_feedback)
	_refresh_assembly_progress()
	_asm_buttons[0].grab_focus()


func is_assembling() -> bool:
	return _asm_root != null


func _unhandled_input(event: InputEvent) -> void:
	if _asm_root == null or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var slot: int = event.physical_keycode - KEY_1
	if slot >= 0 and slot < _asm_buttons.size():
		get_viewport().set_input_as_handled()
		_on_assembly_choice(slot)


func _on_assembly_choice(slot: int) -> void:
	if _asm_root == null or Time.get_ticks_msec() < _asm_ready_at:
		return
	var button: Button = _asm_buttons[slot]
	if button.disabled or _asm_index >= _asm_steps.size():
		return
	var chosen: String = _asm_options[slot]["type"]
	var expected: String = _asm_steps[_asm_index]["type"]
	if chosen == expected:
		_asm_index += 1
		button.disabled = true
		button.modulate = Color(0.6, 1.0, 0.6)
		GameManager.play_sfx("pickup", -6.0)
		_refresh_assembly_progress()
		_asm_feedback.add_theme_color_override("font_color", UIKit.GREEN)
		if _asm_index >= _asm_steps.size():
			_asm_feedback.text = "¡PC ensamblada correctamente!"
			get_tree().create_timer(0.9).timeout.connect(_close_assembly)
		else:
			_asm_feedback.text = "%s instalada. ¿Qué sigue?" % PART_NAMES[chosen]
			_focus_first_enabled()
	else:
		_asm_errors += 1
		GameManager.play_sfx("hit", -8.0)
		_asm_feedback.add_theme_color_override("font_color", UIKit.RED)
		_asm_feedback.text = "¡Esa pieza no va todavía! " + ASSEMBLY_HINTS[expected]
		var flash := button.create_tween()
		flash.tween_property(button, "modulate", Color(1.0, 0.5, 0.5), 0.08)
		flash.tween_property(button, "modulate", Color.WHITE, 0.25)


func _focus_first_enabled() -> void:
	for b in _asm_buttons:
		if not b.disabled:
			b.grab_focus()
			return


func _refresh_assembly_progress() -> void:
	for child in _asm_progress.get_children():
		child.queue_free()
	for i in _asm_steps.size():
		if i > 0:
			_asm_progress.add_child(UIKit.label(">", 10, UIKit.GREY))
		if i < _asm_index:
			var t := TextureRect.new()
			t.texture = GameManager.item_texture(_asm_steps[i]["type"])
			t.custom_minimum_size = Vector2(16, 16)
			_asm_progress.add_child(t)
		else:
			var slot := UIKit.label("?", 10, UIKit.GREY)
			slot.custom_minimum_size = Vector2(16, 16)
			slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_asm_progress.add_child(slot)


func _close_assembly() -> void:
	if _asm_root:
		_asm_root.queue_free()
		_asm_root = null
	get_tree().paused = false
	_asm_on_done.call(_asm_errors)


# ---------------------------------------------------------------- Internos
func _refresh_mission_text() -> void:
	if _needs.is_empty():
		return # objetivo personalizado (set_objective): no sobrescribir
	var parts := PackedStringArray()
	var complete := true
	for item_type in _needs:
		var need: int = _needs[item_type]
		var have: int = mini(_inventory.count(item_type), need)
		parts.append("%s %d/%d" % [item_type, have, need])
		if have < need:
			complete = false
	var text := "   ".join(parts)
	if complete:
		text += "\n¡Llévalos a la MESA DE TRABAJO!"
	mission_needs.text = text


func _make_row(item_type: String, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var icon := TextureRect.new()
	icon.texture = GameManager.item_texture(item_type)
	icon.custom_minimum_size = Vector2(16, 16)
	row.add_child(icon)
	var label := Label.new()
	label.text = "%s x%d" % [item_type, count]
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	return row


func _make_text_row(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	return label

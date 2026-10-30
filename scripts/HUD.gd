extends CanvasLayer
## Interfaz: misión activa, inventario agrupado ("RAM x2"), vidas, nivel,
## barra del jefe, mensajes y pantallas de victoria / game over.

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


func _ready() -> void:
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

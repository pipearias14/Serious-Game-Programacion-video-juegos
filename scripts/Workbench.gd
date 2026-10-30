extends Area2D
## Mesa de trabajo. El Area2D detecta al jugador; el StaticBody2D hijo aporta la colisión física.
## Valida el inventario contra la misión activa, consume los ítems y avanza de nivel.

signal mission_changed(index: int, title: String, needs: Dictionary)
signal mission_completed(index: int)
signal level_advanced(new_level: int)
signal missing_items(text: String)
signal all_missions_completed

## Para añadir misiones, basta con agregar entradas a esta lista.
const MISSIONS := [
	{"title": "PC Básica", "needs": {"RAM": 1, "CPU": 1, "BOARD": 1}},
	{"title": "PC Mejorada", "needs": {"RAM": 2, "CPU": 1, "BOARD": 1}},
	{"title": "PC Gamer", "needs": {"RAM": 2, "CPU": 1, "BOARD": 1, "DISK": 1}},
]



var _player: Node2D = null
var _assembling := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("workbenches")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func mission_count() -> int:
	return MISSIONS.size()


## Llamar tras conectar las señales para publicar la misión activa.
func emit_current_mission() -> void:
	if GameManager.mission_index >= MISSIONS.size():
		return
	var mission: Dictionary = MISSIONS[GameManager.mission_index]
	var title := "MISIÓN %d/%d: %s" % [GameManager.mission_index + 1, MISSIONS.size(), mission["title"]]
	mission_changed.emit(GameManager.mission_index, title, mission["needs"])


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("count_item"):
		return
	_player = body
	if not body.inventory_changed.is_connected(_on_inventory_changed):
		body.inventory_changed.connect(_on_inventory_changed)
	_try_assemble(true)


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		if body.inventory_changed.is_connected(_on_inventory_changed):
			body.inventory_changed.disconnect(_on_inventory_changed)
		_player = null


func _on_inventory_changed(_inventory: Array) -> void:
	if not _assembling:
		_try_assemble(false)


func _try_assemble(notify: bool) -> void:
	if _player == null or GameManager.mission_index >= MISSIONS.size():
		return
	var needs: Dictionary = MISSIONS[GameManager.mission_index]["needs"]
	var missing := PackedStringArray()
	for item_type in needs:
		var need: int = needs[item_type]
		var lacking: int = need - _player.count_item(item_type)
		if lacking > 0:
			missing.append("%s x%d" % [item_type, lacking])

	if missing.is_empty():
		_assembling = true
		_player.consume_items(needs)
		_assembling = false
		_complete_mission()
	elif notify:
		missing_items.emit("Para ensamblar necesitas: " + ", ".join(missing))


func _complete_mission() -> void:
	var finished := GameManager.mission_index
	GameManager.play_sfx("success")
	_pulse()
	mission_completed.emit(finished)
	GameManager.mission_index += 1
	GameManager.level = GameManager.mission_index + 1
	level_advanced.emit(GameManager.level)
	if GameManager.mission_index >= MISSIONS.size():
		all_missions_completed.emit()
	else:
		emit_current_mission()


func _pulse() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.12)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.18)

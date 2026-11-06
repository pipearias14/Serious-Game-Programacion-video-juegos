extends Node2D
## Escena de juego: conecta jugador, mesa de trabajo, enemigos, jefe y HUD.

## Tamaño total del mapa en píxeles. Al ampliar el mapa, súbelo aquí:
## limita la cámara y nada más.
@export var world_size := Vector2(1280, 1080)

@onready var player = $TechPlayer
@onready var workbench = get_tree().get_first_node_in_group("workbenches")
@onready var hud = $HUD
@onready var boss = get_node_or_null("Boss")

var _kills := 0
var _ended := false
var _won := false
var _seen_kinds := {}
var _seen_items := {}
var _start_ms := 0


func _ready() -> void:
	GameManager.reset_missions()
	GameManager.reset_run_stats()
	_start_ms = Time.get_ticks_msec()
	_setup_camera()

	player.inventory_changed.connect(hud.update_inventory)
	player.item_collected.connect(_on_item_collected)
	player.inventory_dropped.connect(_on_inventory_dropped)
	player.lives_changed.connect(hud.set_lives)
	player.lives_changed.connect(_on_lives_changed)
	player.healed.connect(_on_player_healed)
	player.died.connect(_on_player_died)

	for bench in get_tree().get_nodes_in_group("workbenches"):
		bench.mission_changed.connect(hud.on_mission_changed)
		bench.missing_items.connect(hud.on_missing_items)
		bench.level_advanced.connect(_on_level_advanced)
		bench.all_missions_completed.connect(_on_all_missions_completed)
		bench.assembly_requested.connect(_on_assembly_requested)

	for enemy in $Enemies.get_children():
		enemy.died.connect(_on_enemy_died)

	if boss:
		boss.activated.connect(_on_boss_activated)
		boss.health_changed.connect(hud.update_boss)
		boss.died.connect(_on_boss_died)

	hud.update_inventory(player.inventory)
	hud.set_lives(player.lives, player.max_lives)
	_last_lives = player.lives
	workbench.emit_current_mission()
	hud.show_message("Recolecta hardware, elimina virus y ensambla la PC en la mesa", 5.0)
	GameManager.play_music("game")


func _setup_camera() -> void:
	var cam := player.get_node("Camera2D") as Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(world_size.x)
	cam.limit_bottom = int(world_size.y)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif _won and event.is_action_pressed("continue"):
		# Tras ganar, ENTER lleva al test final (post-test).
		GameManager.trivia_mode = "post"
		get_tree().change_scene_to_file("res://scenes/Trivia.tscn")


# ---------------------------------------------------------------- Jugador
func _on_item_collected(item_type: String) -> void:
	# Primera vez en la partida: ficha completa. Después: recordatorio corto.
	if not _seen_items.has(item_type):
		_seen_items[item_type] = true
		hud.show_card(item_type, GameManager.unlock_card(item_type))
	else:
		hud.show_message(GameManager.ITEM_INFO.get(item_type, item_type), 3.0)


var _last_lives := -1


func _on_lives_changed(lives: int, _max_lives: int) -> void:
	if _last_lives >= 0 and lives < _last_lives:
		GameManager.run_stats["lives_lost"] += _last_lives - lives
	_last_lives = lives


func _on_inventory_dropped(count: int) -> void:
	hud.show_message("¡Te infectaron! Perdiste una vida y soltaste %d ítem(s). ¡Recógelos!" % count, 3.5)


func _on_player_healed() -> void:
	hud.show_message(GameManager.ITEM_INFO["LIFE"], 2.5)


func _on_player_died() -> void:
	_ended = true
	GameManager.run_stats["time"] = (Time.get_ticks_msec() - _start_ms) / 1000.0
	GameManager.stop_music()
	hud.show_game_over()


# ---------------------------------------------------------------- Enemigos y jefe
func _on_enemy_died(enemy: Node2D) -> void:
	_kills += 1
	GameManager.run_stats["kills"] = _kills
	hud.set_kills(_kills)
	# Primera vez que se elimina cada tipo de virus en la partida: ficha educativa.
	var kind: String = enemy.kind
	if not _seen_kinds.has(kind):
		_seen_kinds[kind] = true
		hud.show_card(kind, GameManager.unlock_card(kind))


func _on_boss_activated() -> void:
	hud.show_boss_bar(boss.max_health)
	hud.show_card("BOSS", GameManager.unlock_card("BOSS"))
	hud.show_message("¡REY RANSOMWARE! El ransomware secuestra tus archivos y pide un rescate. ¡Dispárale!", 5.0)
	GameManager.play_sfx("boss_roar")
	GameManager.play_music("boss")


func _on_boss_died() -> void:
	if _ended:
		return
	_ended = true
	_won = true
	GameManager.run_stats["won"] = true
	GameManager.run_stats["time"] = (Time.get_ticks_msec() - _start_ms) / 1000.0
	GameManager.stop_music()
	GameManager.play_sfx("success")
	hud.show_victory(_kills)


# ---------------------------------------------------------------- Misiones y niveles
func _on_assembly_requested(bench: Node, title: String, steps: Array) -> void:
	hud.open_assembly(title, steps, func(errors: int):
		GameManager.run_stats["assembly_errors"] += errors
		GameManager.run_stats["pcs_built"] += 1
		bench.finish_assembly(errors))


func _on_level_advanced(new_level: int) -> void:
	hud.set_level(new_level)
	var opened := false
	for gate in get_tree().get_nodes_in_group("gates"):
		if gate.opens_at_level == new_level:
			gate.open()
			opened = true
	if opened:
		GameManager.play_sfx("gate_open")

	if new_level > workbench.mission_count():
		hud.show_message("¡NIVEL FINAL! El REY RANSOMWARE despertó: se abrió la compuerta de la Zona C", 5.0)
	elif opened:
		hud.show_message("¡NIVEL %d! Se abrió una compuerta hacia una nueva zona" % new_level, 4.5)
	else:
		hud.show_message("¡NIVEL %d! PC ensamblada con éxito" % new_level, 4.0)


func _on_all_missions_completed() -> void:
	hud.set_objective("MISIÓN FINAL", "Derrota al REY RANSOMWARE\nen la Zona C (compuerta al sur)")

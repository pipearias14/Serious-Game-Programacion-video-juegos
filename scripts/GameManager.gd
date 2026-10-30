extends Node
## Autoload global (GameManager): constantes de ítems, teclas, sonidos y música.

const ITEM_TYPES := ["RAM", "CPU", "BOARD", "DISK"]
## Ítems que pueden soltar los virus al morir (según el diseño: RAM, CPU, BOARD).
const DROPPABLE_TYPES := ["RAM", "CPU", "BOARD"]

const ITEM_INFO := {
	"RAM": "Memoria RAM: guarda datos temporales mientras la PC trabaja.",
	"CPU": "Procesador (CPU): el cerebro que ejecuta las instrucciones.",
	"BOARD": "Placa base: conecta y comunica todos los componentes.",
	"DISK": "Disco duro: almacena tus archivos de forma permanente.",
	"LIFE": "¡Antivirus de emergencia! Recuperas 1 corazón.",
}

## Mensaje educativo que se muestra al eliminar por primera vez cada tipo de virus.
const VIRUS_INFO := {
	"WORM": "Gusano: malware que se copia a sí mismo y se propaga por la red.",
	"TROJAN": "Troyano: malware disfrazado de programa legítimo para engañarte.",
	"SPAMMER": "Spam: mensajes masivos no deseados, a menudo con enlaces peligrosos (phishing).",
}

var music_enabled := true

## Estado del test de trivia: pre-test (antes de jugar) y post-test (al ganar).
var trivia_mode := "pre"      # "pre" o "post"
var trivia_pre_score := -1    # -1 = sin registrar
var trivia_post_score := -1

## Progreso de misiones (compartido por TODAS las mesas de trabajo).
var mission_index := 0
var level := 1

var _item_scene: PackedScene
var _sfx_cache := {}
var _music_player: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	_register_input()
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -12.0
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_music"):
		toggle_music()


func reset_missions() -> void:
	mission_index = 0
	level = 1

# ---------------------------------------------------------------- Partida / trivia
## Reinicia el ciclo completo: pre-test -> juego -> post-test.
func start_new_run() -> void:
	trivia_mode = "pre"
	trivia_pre_score = -1
	trivia_post_score = -1


# ---------------------------------------------------------------- Entrada
func _register_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("shoot", [KEY_SPACE])
	_bind("restart", [KEY_R])
	_bind("toggle_music", [KEY_M])
	_bind("continue", [KEY_ENTER, KEY_KP_ENTER])


func _bind(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key as Key
		InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------- Ítems
func item_texture(item_type: String) -> Texture2D:
	return load("res://assets/sprites/item_%s.png" % item_type.to_lower()) as Texture2D


func random_drop_type() -> String:
	return DROPPABLE_TYPES.pick_random()


## Crea un HardwareItem en el suelo. `scatter` > 0 lo dispersa alrededor de `origin`
## (sin atravesar muros). `pickup_delay` evita recogerlo de inmediato.
## El contenedor "items_container" debe estar en el origen (0, 0).
func spawn_item(item_type: String, origin: Vector2, scatter: float = 0.0, pickup_delay: float = 0.0) -> void:
	if _item_scene == null:
		_item_scene = load("res://scenes/HardwareItem.tscn") as PackedScene
	var item := _item_scene.instantiate()
	item.item_type = item_type
	item.pickup_delay = pickup_delay
	item.position = _scatter_position(origin, scatter)
	var container := get_tree().get_first_node_in_group("items_container")
	if container == null:
		container = get_tree().current_scene
	# Diferido: esto suele ejecutarse dentro de una señal de física.
	container.add_child.call_deferred(item)


func _scatter_position(origin: Vector2, radius: float) -> Vector2:
	if radius <= 0.0:
		return origin
	var target := origin + Vector2.from_angle(randf() * TAU) * randf_range(radius * 0.6, radius)
	var space := get_viewport().world_2d.direct_space_state
	var query := PhysicsRayQueryParameters2D.create(origin, target, 1 | 16) # Mundo + Mesa
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var hit_pos: Vector2 = hit["position"]
		return origin + (hit_pos - origin) * 0.5
	return target


# ---------------------------------------------------------------- Efectos de sonido
func play_sfx(sfx_name: String, volume_db: float = -6.0) -> void:
	var path := "res://assets/sfx/%s.wav" % sfx_name
	if not _sfx_cache.has(path):
		_sfx_cache[path] = load(path) if ResourceLoader.exists(path) else null
	var stream = _sfx_cache[path]
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


# ---------------------------------------------------------------- Música
## Pistas disponibles en res://assets/music/: "menu", "game", "boss".
func play_music(track: String) -> void:
	if track == _music_name and _music_player.playing:
		return
	var path := "res://assets/music/%s.wav" % track
	if not ResourceLoader.exists(path):
		return
	_music_name = track
	_music_player.stream = load(path)
	if music_enabled:
		_music_player.play()


func stop_music() -> void:
	_music_name = ""
	_music_player.stop()


func toggle_music() -> void:
	music_enabled = not music_enabled
	if music_enabled and _music_name != "":
		_music_player.play()
	else:
		_music_player.stop()


func _on_music_finished() -> void:
	if music_enabled and _music_name != "":
		_music_player.play() # bucle

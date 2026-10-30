@tool
extends StaticBody2D
## Muro / obstáculo / compuerta rectangular.
## - Repite la textura en mosaico y crea su propia colisión según `wall_size`.
## - Es @tool: al cambiar `wall_size` en el Inspector lo ves redimensionarse en el editor.
## - La posición del nodo es su esquina superior izquierda.
## - Si `opens_at_level` > 0, funciona como compuerta: se abre al llegar a ese nivel.

@export var wall_size := Vector2(16, 16):
	set(value):
		wall_size = value
		_refresh()
@export var tile_texture: Texture2D:
	set(value):
		tile_texture = value
		queue_redraw()
@export var opens_at_level := 0

var _collision: CollisionShape2D


func _ready() -> void:
	_refresh()
	if opens_at_level > 0 and not Engine.is_editor_hint():
		add_to_group("gates")


func _refresh() -> void:
	if not is_inside_tree():
		return
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.shape = RectangleShape2D.new()
		add_child(_collision)
	(_collision.shape as RectangleShape2D).size = wall_size
	_collision.position = wall_size / 2.0
	queue_redraw()


func _draw() -> void:
	if tile_texture == null:
		draw_rect(Rect2(Vector2.ZERO, wall_size), Color.GRAY)
		return
	var tile := tile_texture.get_size()
	var y := 0.0
	while y < wall_size.y:
		var x := 0.0
		while x < wall_size.x:
			draw_texture(tile_texture, Vector2(x, y))
			x += tile.x
		y += tile.y


## Se desvanece y deja de bloquear el paso.
func open() -> void:
	if _collision:
		_collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)

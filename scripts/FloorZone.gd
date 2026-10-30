@tool
extends Node2D
## Zona de suelo rectangular hecha de baldosas repetidas.
## Para ampliar el mapa: instancia otra FloorZone, ponla donde quieras (esquina superior izquierda),
## cambia `zone_size` y, si quieres, otra `tile_texture`.

@export var zone_size := Vector2(640, 360):
	set(value):
		zone_size = value
		queue_redraw()
@export var tile_texture: Texture2D:
	set(value):
		tile_texture = value
		queue_redraw()


func _draw() -> void:
	if tile_texture == null:
		draw_rect(Rect2(Vector2.ZERO, zone_size), Color(0.15, 0.17, 0.27))
		return
	var ts := tile_texture.get_size()
	var y := 0.0
	while y < zone_size.y:
		var h := minf(ts.y, zone_size.y - y)
		var x := 0.0
		while x < zone_size.x:
			var w := minf(ts.x, zone_size.x - x)
			draw_texture_rect_region(tile_texture, Rect2(x, y, w, h), Rect2(0, 0, w, h))
			x += ts.x
		y += ts.y

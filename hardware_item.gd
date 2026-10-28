class_name HardwareItem
extends Area2D

@export var item_type: String = "RAM"
@onready var sprite: Sprite2D = $Sprite2D # Asegúrate de tener un nodo Sprite2D hijo

func _ready() -> void:
	# Convertimos el string a minúsculas para que coincida con tus archivos
	var nombre_archivo = "item_" + item_type.to_lower() + ".png"
	var ruta_textura = "res://sprites_serious_game/" + nombre_archivo
	
	if ResourceLoader.exists(ruta_textura):
		sprite.texture = load(ruta_textura)

func _on_body_entered(body: Node2D) -> void:
	if body is TechPlayer:
		body.collect_item(item_type)
		queue_free()

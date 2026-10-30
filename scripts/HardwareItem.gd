extends Area2D
## Objeto recogible. El sprite se carga según `item_type`.
## RAM / CPU / BOARD / DISK van al inventario; LIFE devuelve un corazón al jugador.

@export_enum("RAM", "CPU", "BOARD", "DISK", "LIFE") var item_type: String = "RAM":
	set(value):
		item_type = value
		if is_node_ready():
			_update_sprite()
## Segundos antes de poder recogerlo (útil para ítems soltados por el jugador).
@export var pickup_delay := 0.0

var _collected := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_update_sprite()
	body_entered.connect(_on_body_entered)

	var bob := create_tween().set_loops()
	bob.tween_property(sprite, "position:y", -2.0, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(sprite, "position:y", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

	if pickup_delay > 0.0:
		monitoring = false
		sprite.modulate.a = 0.5
		# Tween del propio nodo: si el ítem se libera, el temporizador se cancela solo.
		var wait := create_tween()
		wait.tween_interval(pickup_delay)
		wait.tween_callback(_enable_pickup)


func _enable_pickup() -> void:
	sprite.modulate.a = 1.0
	monitoring = true # al reactivarse detecta a quien ya esté encima


func _update_sprite() -> void:
	sprite.texture = GameManager.item_texture(item_type)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if item_type == "LIFE":
		if body.has_method("heal") and body.heal(1):
			_collected = true
			queue_free()
		return
	if body.has_method("add_item"):
		_collected = true
		body.add_item(item_type)
		queue_free()

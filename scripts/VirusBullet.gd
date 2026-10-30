extends Area2D
## Proyectil enemigo (Spammer y jefe). Al tocar al jugador le hace daño.

@export var speed := 105.0
@export var lifetime := 4.0

var direction := Vector2.RIGHT
var _age := 0.0


func _ready() -> void:
	add_to_group("enemy_bullets")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_virus_hit"):
		body.take_virus_hit(global_position)
	queue_free()

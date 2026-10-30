extends Area2D
## Proyectil del técnico. Daña virus y se destruye al chocar con muros o con la mesa.

@export var speed := 340.0
@export var max_distance := 280.0
@export var damage := 1

var direction := Vector2.RIGHT
var _travelled := 0.0


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	_travelled += step.length()
	if _travelled >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

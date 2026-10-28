class_name AntivirusLaser
extends Area2D

@export var SPEED: float = 300.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Rotar el sprite del láser para que apunte a la dirección de disparo
	if direction == Vector2.UP:
		rotation_degrees = -90
	elif direction == Vector2.DOWN:
		rotation_degrees = 90
	elif direction == Vector2.LEFT:
		rotation_degrees = 180

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

# Conecta la señal 'area_entered' del Hitbox del virus o 'body_entered' del Virus
func _on_body_entered(body: Node2D) -> void:
	if body is VirusEnemy:
		body.take_damage()
		queue_free() # Destruye el láser al impactar

# Conecta la señal 'screen_exited' del VisibleOnScreenNotifier2D
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free() # Destruye el láser si sale de la pantalla

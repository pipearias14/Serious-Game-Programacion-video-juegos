extends Area2D
## Proyectil del técnico. Daña virus y se destruye al chocar con muros o con la mesa.

@export var speed := 340.0
@export var max_distance := 280.0
@export var damage := 1

var direction := Vector2.RIGHT
var _travelled := 0.0


const TRAIL_COLORS := [Color(0.45, 0.94, 0.97, 0.9), Color(0.25, 0.65, 0.96, 0.8), Color(0.96, 0.96, 0.96, 0.9)]


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	_add_trail()


## Rastro: partículas que quedan en el mundo (no se mueven con el láser) y se desvanecen.
func _add_trail() -> void:
	var trail := CPUParticles2D.new()
	trail.local_coords = false
	trail.amount = 14
	trail.lifetime = 0.18
	trail.gravity = Vector2.ZERO
	trail.spread = 180.0
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 8.0
	trail.scale_amount_min = 1.0
	trail.scale_amount_max = 2.0
	trail.position = Vector2(-5, 0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1, 1, 1, 0))
	trail.color_ramp = ramp
	var tint := Gradient.new()
	tint.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	tint.set_color(0, TRAIL_COLORS[0])
	tint.set_color(1, TRAIL_COLORS[1])
	tint.add_point(0.66, TRAIL_COLORS[2])
	trail.color_initial_ramp = tint
	trail.show_behind_parent = true
	add_child(trail)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	_travelled += step.length()
	if _travelled >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	# Chispitas en el punto de impacto.
	GameManager.spawn_burst(global_position, TRAIL_COLORS, 6, 45.0, 0.25, 1.5)
	queue_free()

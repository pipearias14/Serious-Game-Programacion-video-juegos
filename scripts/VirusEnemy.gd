extends CharacterBody2D
## Virus con IA de dos estados: PATROL (merodea cerca de su origen) y
## CHASE (persigue al jugador cuando entra en la DetectionZone).
## Hay 4 tipos (`kind`); para crear uno nuevo, añade una entrada a KINDS.

signal died(enemy: Node2D)

enum State { PATROL, CHASE }

const BULLET_SCENE := preload("res://scenes/VirusBullet.tscn")

## texture: archivo en assets/sprites (sin .png) · detect: radio de detección
## drops: ítems al morir · shoots: dispara a distancia · keep_distance: distancia que mantiene
const KINDS := {
	"WORM": {"texture": "virus_worm", "health": 2, "patrol_speed": 32.0, "chase_speed": 60.0,
		"detect": 90.0, "drops": 1, "shoots": false},
	"TROJAN": {"texture": "virus_trojan", "health": 5, "patrol_speed": 22.0, "chase_speed": 42.0,
		"detect": 80.0, "drops": 2, "shoots": false},
	"RUNNER": {"texture": "virus_runner", "health": 1, "patrol_speed": 55.0, "chase_speed": 100.0,
		"detect": 120.0, "drops": 1, "shoots": false},
	"SPAMMER": {"texture": "virus_spammer", "health": 2, "patrol_speed": 28.0, "chase_speed": 42.0,
		"detect": 140.0, "drops": 1, "shoots": true, "keep_distance": 85.0, "fire_interval": 1.8},
}

@export_enum("WORM", "TROJAN", "RUNNER", "SPAMMER") var kind: String = "WORM"
@export var patrol_radius := 60.0
## Probabilidad de soltar además un corazón (vida) al morir.
@export_range(0.0, 1.0) var heart_chance := 0.12

var state: State = State.PATROL
var health := 2

var _stats: Dictionary
var _home := Vector2.ZERO
var _patrol_target := Vector2.ZERO
var _wait_time := 0.0
var _fire_timer := 1.0
var _target: Node2D = null
var _dead := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var detection_shape: CollisionShape2D = $DetectionZone/CollisionShape2D
@onready var contact_area: Area2D = $ContactArea


func _ready() -> void:
	_stats = KINDS.get(kind, KINDS["WORM"])
	health = _stats["health"]
	sprite.texture = load("res://assets/sprites/%s.png" % _stats["texture"]) as Texture2D
	# Forma propia por instancia (el recurso de la escena es compartido).
	var zone_shape := CircleShape2D.new()
	zone_shape.radius = _stats["detect"]
	detection_shape.shape = zone_shape

	_home = global_position
	_pick_patrol_target()
	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)
	_apply_state_visuals()

	var bob := create_tween().set_loops()
	bob.tween_property(sprite, "scale", Vector2(1.1, 0.9), 0.35)
	bob.tween_property(sprite, "scale", Vector2(0.95, 1.05), 0.35)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	match state:
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase(delta)
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()
	_check_contact()


# ---------------------------------------------------------------- Estados
func _patrol(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time -= delta
		velocity = Vector2.ZERO
		return
	var to_target := _patrol_target - global_position
	if to_target.length() < 4.0 or get_slide_collision_count() > 0:
		_wait_time = randf_range(0.5, 1.5)
		_pick_patrol_target()
		velocity = Vector2.ZERO
		return
	velocity = to_target.normalized() * float(_stats["patrol_speed"])


func _chase(delta: float) -> void:
	if not is_instance_valid(_target):
		_set_state(State.PATROL)
		return
	var to_player := _target.global_position - global_position
	var speed: float = _stats["chase_speed"]
	if _stats["shoots"]:
		# Tirador: mantiene la distancia y dispara.
		var keep: float = _stats["keep_distance"]
		var dist := to_player.length()
		if dist > keep + 12.0:
			velocity = to_player.normalized() * speed
		elif dist < keep - 12.0:
			velocity = -to_player.normalized() * speed
		else:
			velocity = Vector2.ZERO
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = _stats["fire_interval"]
			_shoot_at(to_player.normalized())
	else:
		velocity = to_player.normalized() * speed


func _shoot_at(dir: Vector2) -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.direction = dir
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + dir * 8.0
	GameManager.play_sfx("enemy_shoot", -14.0)


func _set_state(new_state: State) -> void:
	state = new_state
	if state == State.PATROL:
		_target = null
		_pick_patrol_target()
	_apply_state_visuals()


func _pick_patrol_target() -> void:
	_patrol_target = _home + Vector2.from_angle(randf() * TAU) * randf_range(10.0, patrol_radius)


func _apply_state_visuals() -> void:
	sprite.modulate = _state_color()


func _state_color() -> Color:
	return Color(1.0, 0.6, 0.6) if state == State.CHASE else Color.WHITE


# ---------------------------------------------------------------- Detección
func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_target = body
		_set_state(State.CHASE)


func _on_detection_body_exited(body: Node2D) -> void:
	if body == _target:
		_set_state(State.PATROL)


## Si el jugador toca al virus, pierde su inventario y una vida (lo gestiona TechPlayer).
func _check_contact() -> void:
	for body in contact_area.get_overlapping_bodies():
		if body.has_method("take_virus_hit"):
			body.take_virus_hit(global_position)


# ---------------------------------------------------------------- Daño y muerte
func take_damage(amount: int = 1) -> void:
	if _dead:
		return
	health -= amount
	sprite.modulate = Color(3, 3, 3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", _state_color(), 0.15)
	if health <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	GameManager.play_sfx("enemy_die")
	var drops: int = _stats["drops"]
	for i in drops:
		GameManager.spawn_item(GameManager.random_drop_type(), global_position, 14.0 if drops > 1 else 0.0)
	if randf() < heart_chance:
		GameManager.spawn_item("LIFE", global_position, 18.0)
	died.emit(self)
	queue_free()

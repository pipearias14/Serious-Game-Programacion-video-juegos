extends CharacterBody2D
## REY RANSOMWARE: jefe final. Se activa cuando el jugador entra en su ActivationZone.
## Fase 1: persigue despacio y dispara abanicos de 3 proyectiles.
## Fase 2 (con la mitad de vida): más rápido, ráfagas circulares, abanicos de 5 y embestidas.

signal activated
signal health_changed(current: int, maximum: int)
signal died

enum Mode { WALK, WINDUP, DASH }

const BULLET_SCENE := preload("res://scenes/VirusBullet.tscn")

@export var max_health := 40
@export var walk_speed := 36.0
@export var phase2_walk_speed := 55.0
@export var dash_speed := 240.0

var health := 40
var phase := 1

var _active := false
var _dead := false
var _mode := Mode.WALK
var _mode_time := 0.0
var _attack_timer := 1.5
var _dash_cooldown := 4.0
var _dash_dir := Vector2.ZERO
var _attack_count := 0
var _target: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var activation_zone: Area2D = $ActivationZone
@onready var contact_area: Area2D = $ContactArea


func _ready() -> void:
	health = max_health
	activation_zone.body_entered.connect(_on_activation_body_entered)
	var bob := create_tween().set_loops()
	bob.tween_property(sprite, "position:y", -2.0, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(sprite, "position:y", 2.0, 0.6).set_trans(Tween.TRANS_SINE)


func _on_activation_body_entered(body: Node2D) -> void:
	if _active or _dead:
		return
	if body.is_in_group("player"):
		_target = body
		_active = true
		activation_zone.set_deferred("monitoring", false)
		activated.emit()
		health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if _dead or not _active or not is_instance_valid(_target):
		return
	match _mode:
		Mode.WALK:
			_walk(delta)
		Mode.WINDUP:
			velocity = Vector2.ZERO
			_mode_time -= delta
			if _mode_time <= 0.0:
				_dash_dir = (_target.global_position - global_position).normalized()
				_mode = Mode.DASH
				_mode_time = 0.55
				sprite.modulate = _phase_color()
		Mode.DASH:
			velocity = _dash_dir * dash_speed
			_mode_time -= delta
			if _mode_time <= 0.0 or get_slide_collision_count() > 0:
				_mode = Mode.WALK
				_dash_cooldown = 4.5
	move_and_slide()
	_check_contact()


func _walk(delta: float) -> void:
	var to_player := _target.global_position - global_position
	var speed := phase2_walk_speed if phase == 2 else walk_speed
	if to_player.length() > 60.0:
		velocity = to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 1.9 if phase == 1 else 1.5
		_attack(to_player.normalized())

	if phase == 2:
		_dash_cooldown -= delta
		if _dash_cooldown <= 0.0:
			_mode = Mode.WINDUP
			_mode_time = 0.7
			sprite.modulate = Color(2.5, 2.5, 2.5) # aviso de embestida
			GameManager.play_sfx("boss_roar", -10.0)


func _attack(aim: Vector2) -> void:
	_attack_count += 1
	if phase == 1:
		for deg in [-22.0, 0.0, 22.0]:
			_fire(aim.rotated(deg_to_rad(deg)))
	elif _attack_count % 2 == 0:
		var offset := randf() * 0.3
		for i in 12:
			_fire(Vector2.from_angle(TAU * i / 12.0 + offset))
	else:
		for deg in [-36.0, -18.0, 0.0, 18.0, 36.0]:
			_fire(aim.rotated(deg_to_rad(deg)))
	GameManager.play_sfx("enemy_shoot", -8.0)


func _fire(dir: Vector2) -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.direction = dir
	bullet.speed = 105.0
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + dir * 16.0


func _check_contact() -> void:
	for body in contact_area.get_overlapping_bodies():
		if body.has_method("take_virus_hit"):
			body.take_virus_hit(global_position)


func _phase_color() -> Color:
	return Color(1.0, 0.7, 0.55) if phase == 2 else Color.WHITE


# ---------------------------------------------------------------- Daño y muerte
func take_damage(amount: int = 1) -> void:
	if _dead:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	sprite.modulate = Color(3, 3, 3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", _phase_color(), 0.12)
	if phase == 1 and float(health) <= max_health * 0.5:
		phase = 2
		GameManager.play_sfx("boss_roar")
	if health <= 0:
		_die()


func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	GameManager.play_sfx("boss_die")
	get_tree().call_group("enemy_bullets", "queue_free")
	died.emit()
	var tween := create_tween()
	for i in 6:
		tween.tween_property(sprite, "modulate", Color(3, 3, 3), 0.06)
		tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), 0.06)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

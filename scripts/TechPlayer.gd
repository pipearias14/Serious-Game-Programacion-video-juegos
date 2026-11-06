extends CharacterBody2D
## Técnico informático: se mueve en 4 direcciones, dispara láseres antivirus,
## guarda hardware en su inventario y tiene vidas.

signal inventory_changed(inventory: Array)
signal item_collected(item_type: String)
signal inventory_dropped(count: int)
signal lives_changed(lives: int, max_lives: int)
signal healed
signal died

const LASER_SCENE := preload("res://scenes/AntivirusLaser.tscn")

@export var speed := 110.0
@export var fire_cooldown := 0.30
@export var invulnerable_time := 1.2
@export var drop_scatter := 40.0
@export var max_lives := 3
## Cuadros por segundo de la animación de caminar.
@export var walk_fps := 8.0

## Inventario: lista de Strings, p. ej. ["RAM", "CPU", "RAM"].
var inventory: Array = []
var facing := Vector2.DOWN
var lives := 3

var _horizontal_priority := true
var _can_shoot := true
var _invulnerable := false
var _dead := false
var _knockback := Vector2.ZERO
var _blink_tween: Tween
var _tex_down: Texture2D
var _tex_up: Texture2D
var _tex_side: Texture2D
var _walk_time := 0.0

## Pistola: visible un momento después de cada disparo, con retroceso y destello.
const GUN_SHOW_TIME := 0.35
const RECOIL_TIME := 0.08
const FLASH_TIME := 0.06
## Por dirección: textura, esquina sup-izq de la pistola y punta del cañón
## (relativas al centro del jugador). La izquierda es la derecha en espejo.
const GUN_DATA := {
	Vector2.RIGHT: ["res://assets/sprites/gun_side.png", Vector2(2, 1), Vector2(10, 2)],
	Vector2.LEFT: ["res://assets/sprites/gun_side.png", Vector2(-10, 1), Vector2(-10, 2)],
	Vector2.DOWN: ["res://assets/sprites/gun_down.png", Vector2(2, 3), Vector2(6, 10)],
	Vector2.UP: ["res://assets/sprites/gun_up.png", Vector2(3, -1), Vector2(7, -2)],
}
var _gun: Sprite2D
var _flash: Sprite2D
var _gun_time := 0.0
var _recoil_time := 0.0
var _flash_time := 0.0
var _last_walk_frame := -1
var _shake_strength := 0.0
var _shake_time := 0.0
var _shake_duration := 0.0
const DUST_COLORS := [Color(0.75, 0.78, 0.85, 0.9), Color(0.55, 0.6, 0.7, 0.8)]

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	lives = max_lives
	# Hojas de 4 cuadros (64x16): reposo, paso, reposo, paso.
	_tex_down = load("res://assets/sprites/player_down_walk.png") as Texture2D
	_tex_up = load("res://assets/sprites/player_up_walk.png") as Texture2D
	_tex_side = load("res://assets/sprites/player_side_walk.png") as Texture2D
	sprite.hframes = 4
	_update_sprite()
	_animate_walk(false, 0.0)
	_create_gun()


func _process(delta: float) -> void:
	_animate_gun(delta)
	_update_shake(delta)


## Sacudida de cámara: se desvanece a lo largo de `duration`.
func shake(strength: float, duration: float = 0.25) -> void:
	if strength >= _shake_strength * (_shake_time / maxf(_shake_duration, 0.001)):
		_shake_strength = strength
		_shake_time = duration
		_shake_duration = duration


func _update_shake(delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if _shake_time <= 0.0:
		cam.offset = Vector2.ZERO
		return
	_shake_time = maxf(_shake_time - delta, 0.0)
	var k := _shake_strength * (_shake_time / _shake_duration)
	cam.offset = Vector2(randf_range(-k, k), randf_range(-k, k)).round()


func _physics_process(delta: float) -> void:
	var dir := _read_direction()
	if dir != Vector2.ZERO:
		facing = dir
		_update_sprite()
	_animate_walk(dir != Vector2.ZERO, delta)
	velocity = dir * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()

	if Input.is_action_pressed("shoot") and _can_shoot:
		_shoot()


## Solo 4 direcciones: si se pulsan dos ejes a la vez gana el último pulsado.
func _read_direction() -> Vector2:
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		_horizontal_priority = true
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
		_horizontal_priority = false
	var x := Input.get_axis("move_left", "move_right")
	var y := Input.get_axis("move_up", "move_down")
	if x != 0.0 and y != 0.0:
		if _horizontal_priority:
			y = 0.0
		else:
			x = 0.0
	return Vector2(x, y)


func _update_sprite() -> void:
	if facing == Vector2.UP:
		sprite.texture = _tex_up
		sprite.flip_h = false
	elif facing == Vector2.DOWN:
		sprite.texture = _tex_down
		sprite.flip_h = false
	elif facing == Vector2.LEFT:
		sprite.texture = _tex_side
		sprite.flip_h = true
	else:
		sprite.texture = _tex_side
		sprite.flip_h = false


## Avanza el ciclo de caminar mientras hay movimiento; en reposo vuelve al cuadro 0.
func _animate_walk(moving: bool, delta: float) -> void:
	if not moving:
		_walk_time = 0.0
		sprite.frame = 1 if facing.x != 0.0 else 0  # de lado, el cuadro 1 es la pose de pie
		sprite.offset.y = 0.0
		return
	_walk_time += delta * walk_fps
	var f := int(_walk_time) % 4
	sprite.frame = f
	# Pequeño rebote: el cuerpo baja 1px en los cuadros de paso.
	var step_frame := f % 2 == (0 if facing.x != 0.0 else 1)
	sprite.offset.y = 1.0 if step_frame else 0.0
	# Polvito en cada pisada (solo si de verdad avanza, no contra un muro).
	if step_frame and f != _last_walk_frame and get_real_velocity().length() > 20.0:
		GameManager.spawn_burst(global_position + Vector2(0, 11), DUST_COLORS, 4, 14.0, 0.35, 1.5)
	_last_walk_frame = f


# ---------------------------------------------------------------- Disparo
func _shoot() -> void:
	_can_shoot = false
	var laser := LASER_SCENE.instantiate()
	laser.direction = facing
	get_tree().current_scene.add_child(laser)
	# El láser sale de la punta de la pistola.
	laser.global_position = global_position + (_gun_data()[2] + facing * 2.0) * sprite.scale
	_gun_time = GUN_SHOW_TIME
	_recoil_time = RECOIL_TIME
	_flash_time = FLASH_TIME
	_animate_gun(0.0)
	GameManager.play_sfx("laser")
	# Tween del propio nodo (se cancela solo si el jugador se libera).
	var cooldown := create_tween()
	cooldown.tween_interval(fire_cooldown)
	cooldown.tween_callback(_reset_shoot)


func _reset_shoot() -> void:
	_can_shoot = true


## La pistola y el destello son hijos del sprite: heredan el parpadeo y el fundido al morir.
func _create_gun() -> void:
	_gun = Sprite2D.new()
	_gun.name = "Gun"
	_gun.centered = false
	_gun.visible = false
	sprite.add_child(_gun)
	_flash = Sprite2D.new()
	_flash.name = "MuzzleFlash"
	_flash.texture = load("res://assets/sprites/muzzle_flash.png") as Texture2D
	_flash.visible = false
	sprite.add_child(_flash)


## Datos de la pistola según la dirección (tolera ejes analógicos, p. ej. x = 0.6).
func _gun_data() -> Array:
	if absf(facing.x) > absf(facing.y):
		return GUN_DATA[Vector2.RIGHT if facing.x > 0.0 else Vector2.LEFT]
	return GUN_DATA[Vector2.DOWN if facing.y > 0.0 else Vector2.UP]


func _animate_gun(delta: float) -> void:
	_gun_time = maxf(_gun_time - delta, 0.0)
	_recoil_time = maxf(_recoil_time - delta, 0.0)
	_flash_time = maxf(_flash_time - delta, 0.0)
	_gun.visible = _gun_time > 0.0 and not _dead
	_flash.visible = _flash_time > 0.0 and _gun.visible
	if not _gun.visible:
		return
	var data := _gun_data()
	_gun.texture = load(data[0]) as Texture2D
	_gun.flip_h = data == GUN_DATA[Vector2.LEFT]
	# Retroceso: la pistola se echa 1px hacia atrás justo después del disparo.
	var recoil := -facing if _recoil_time > 0.0 else Vector2.ZERO
	var bob := Vector2(0, sprite.offset.y)
	_gun.position = data[1] + recoil + bob
	_flash.position = data[2] + facing * 2.0 + bob


# ---------------------------------------------------------------- Inventario
func add_item(item_type: String) -> void:
	inventory.append(item_type)
	inventory_changed.emit(inventory)
	item_collected.emit(item_type)
	GameManager.play_sfx("pickup")


func count_item(item_type: String) -> int:
	return inventory.count(item_type)


## Consume los ítems de una receta, p. ej. {"RAM": 2, "CPU": 1}.
func consume_items(needs: Dictionary) -> void:
	for item_type in needs:
		for i in int(needs[item_type]):
			inventory.erase(item_type)
	inventory_changed.emit(inventory)


# ---------------------------------------------------------------- Vidas y daño
## Cualquier ataque enemigo (contacto o proyectil) llama a esto:
## el jugador pierde 1 vida y suelta todo su inventario.
func take_virus_hit(from_position: Vector2) -> void:
	if _invulnerable or _dead:
		return
	_invulnerable = true
	lives -= 1
	lives_changed.emit(lives, max_lives)
	_knockback = (global_position - from_position).normalized() * 260.0
	shake(4.0, 0.3)
	_drop_inventory()

	if lives <= 0:
		_die()
		return

	GameManager.play_sfx("hit")
	_blink_tween = create_tween().set_loops(maxi(1, int(invulnerable_time / 0.2)))
	_blink_tween.tween_property(sprite, "modulate:a", 0.25, 0.1)
	_blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	var timer := create_tween()
	timer.tween_interval(invulnerable_time)
	timer.tween_callback(_end_invulnerability)


func _end_invulnerability() -> void:
	if _blink_tween:
		_blink_tween.kill()
	sprite.modulate.a = 1.0
	_invulnerable = false


## Devuelve true si realmente recuperó vida.
func heal(amount: int = 1) -> bool:
	if _dead or lives >= max_lives:
		return false
	lives = mini(lives + amount, max_lives)
	lives_changed.emit(lives, max_lives)
	healed.emit()
	GameManager.play_sfx("heal")
	return true


func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	GameManager.play_sfx("game_over")
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 0.0), 0.8)
	died.emit()


## Vacía el inventario instanciando cada ítem en el suelo, alrededor del jugador.
func _drop_inventory() -> void:
	if inventory.is_empty():
		return
	var count := inventory.size()
	for item_type in inventory:
		GameManager.spawn_item(item_type, global_position, drop_scatter, 1.5)
	inventory.clear()
	inventory_changed.emit(inventory)
	inventory_dropped.emit(count)

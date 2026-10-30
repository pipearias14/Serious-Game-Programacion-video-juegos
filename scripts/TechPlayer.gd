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

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	lives = max_lives
	_tex_down = load("res://assets/sprites/player_down.png") as Texture2D
	_tex_up = load("res://assets/sprites/player_up.png") as Texture2D
	_tex_side = load("res://assets/sprites/player_side.png") as Texture2D
	_update_sprite()


func _physics_process(delta: float) -> void:
	var dir := _read_direction()
	if dir != Vector2.ZERO:
		facing = dir
		_update_sprite()
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


# ---------------------------------------------------------------- Disparo
func _shoot() -> void:
	_can_shoot = false
	var laser := LASER_SCENE.instantiate()
	laser.direction = facing
	get_tree().current_scene.add_child(laser)
	laser.global_position = global_position + facing * 10.0 + Vector2(0, 2)
	GameManager.play_sfx("laser")
	# Tween del propio nodo (se cancela solo si el jugador se libera).
	var cooldown := create_tween()
	cooldown.tween_interval(fire_cooldown)
	cooldown.tween_callback(_reset_shoot)


func _reset_shoot() -> void:
	_can_shoot = true


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

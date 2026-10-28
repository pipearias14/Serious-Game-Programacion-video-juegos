class_name TechPlayer
extends CharacterBody2D

signal inventory_changed(current_inventory: Array)

@export var SPEED: float = 400.0
var inventory: Array[String] = []

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var facing_direction: Vector2 = Vector2.DOWN

@export var item_scene_template: PackedScene
@export var laser_scene: PackedScene # <--- Asignaremos el láser aquí

func _physics_process(_delta: float) -> void:
	# Sistema de Disparo
	if Input.is_action_just_pressed("ui_accept"): # Barra espaciadora
		shoot_laser()
	
	# Movimiento en 4 direcciones
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector2.ZERO
	
	if abs(input_dir.x) > abs(input_dir.y):
		direction = Vector2(sign(input_dir.x), 0)
	elif abs(input_dir.y) > 0:
		direction = Vector2(0, sign(input_dir.y))
		
	velocity = direction * SPEED
	
	if direction.x > 0:
		facing_direction = Vector2.RIGHT
		animated_sprite_2d.play("walk_right")
	elif direction.x < 0:
		facing_direction = Vector2.LEFT
		animated_sprite_2d.play("walk_left")
	elif direction.y > 0:
		facing_direction = Vector2.DOWN
		animated_sprite_2d.play("walk_down")
	elif direction.y < 0:
		facing_direction = Vector2.UP
		animated_sprite_2d.play("walk_up")
		
	if direction == Vector2.ZERO:
		animated_sprite_2d.pause()

	move_and_slide()

# --- NUEVA FUNCIÓN DE DISPARO ---
func shoot_laser() -> void:
	if laser_scene:
		var laser = laser_scene.instantiate()
		laser.direction = facing_direction
		# Posiciona el láser un poco más adelante del jugador
		laser.global_position = global_position + (facing_direction * 15)
		get_parent().add_child(laser)



func collect_item(type: String) -> void:
	inventory.append(type)
	inventory_changed.emit(inventory) # Avisar al HUD

func drop_all_inventory() -> void:
	if inventory.is_empty():
		return
	for item_name in inventory:
		if item_scene_template:
			var dropped = item_scene_template.instantiate()
			dropped.item_type = item_name
			dropped.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			get_parent().call_deferred("add_child", dropped)
	
	inventory.clear()
	inventory_changed.emit(inventory) # Avisar al HUD que está vacío

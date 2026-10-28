class_name VirusEnemy
extends CharacterBody2D

enum State { PATROL, CHASE }
var current_state: State = State.PATROL

@export var patrol_speed: float = 100.0
@export var chase_speed: float = 180.0

var direction: Vector2 = Vector2.DOWN
var dirs: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

var health: int = 1
var player_target: Node2D = null

@export var hardware_scene: PackedScene 

func _ready() -> void:
	direction = dirs.pick_random()

func _physics_process(_delta: float) -> void:
	match current_state:
		State.PATROL:
			velocity = direction * patrol_speed
			if move_and_slide():
				direction = dirs.pick_random()
				
		State.CHASE:
			if player_target:
				direction = (player_target.global_position - global_position).normalized()
				velocity = direction * chase_speed
				move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is TechPlayer:
		body.drop_all_inventory()

func take_damage() -> void:
	health -= 1
	if health <= 0:
		die()

func die() -> void:
	if hardware_scene:
		var items = ["RAM", "CPU", "BOARD"]
		var dropped_item = hardware_scene.instantiate()
		dropped_item.item_type = items.pick_random()
		dropped_item.global_position = global_position 
		get_parent().call_deferred("add_child", dropped_item)
	
	queue_free()

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body is TechPlayer:
		player_target = body
		current_state = State.CHASE

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body is TechPlayer:
		player_target = null
		current_state = State.PATROL
		direction = dirs.pick_random()

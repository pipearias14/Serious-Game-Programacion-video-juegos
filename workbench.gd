class_name Workbench
extends Area2D

var required_parts: Array[String] = ["RAM", "CPU", "BOARD"]

func _on_body_entered(body: Node2D) -> void:
	if body is TechPlayer:
		var has_all_parts = true
		for part in required_parts:
			if not body.inventory.has(part):
				has_all_parts = false
				break
				
		if has_all_parts:
			print("¡PC Construido! Misión completada.")
		else:
			print("Faltan piezas. Necesitas: RAM, CPU y BOARD.")

extends CanvasLayer

@onready var container = $HBoxContainer

func update_inventory(inventory: Array) -> void:
	# 1. Limpiar los iconos actuales
	for child in container.get_children():
		child.queue_free()
		
	# 2. Contar cuántas piezas hay de cada tipo en el inventario
	var item_counts = {}
	for item in inventory:
		if item_counts.has(item):
			item_counts[item] += 1
		else:
			item_counts[item] = 1
			
	# 3. Crear un grupo (icono + texto) por cada pieza única
	for item in item_counts.keys():
		# Contenedor horizontal para emparejar la imagen y el texto
		var item_group = HBoxContainer.new()
		
		# Crear la imagen
	
		var icon = TextureRect.new()
		var texture_path = "res://sprites_serious_game/item_" + item.to_lower() + ".png" 
		if ResourceLoader.exists(texture_path):
			icon.texture = load(texture_path)
			
		# --- CONFIGURACIÓN DE TAMAÑO DEL ÍCONO ---
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32) # Cambia a (24, 24) o (16, 16) si aún lo ves grande
			
		# Crear el texto con la cantidad
		var label = Label.new()
		label.text = " x" + str(item_counts[item])
		
		# Añadir la imagen y el texto al pequeño grupo
		item_group.add_child(icon)
		item_group.add_child(label)
		
		# Añadir el grupo completo al contenedor principal del HUD
		container.add_child(item_group)

func _on_tech_player_inventory_changed(current_inventory: Array) -> void:
	update_inventory(current_inventory)

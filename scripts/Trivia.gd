extends Node2D
## Test de trivia. Se usa dos veces:
##   - "pre":  antes de jugar (diagnóstico, sin mostrar las respuestas correctas)
##   - "post": al ganar (muestra si acertaste y por qué) y compara con el pre-test.

const Data := preload("res://scripts/TriviaData.gd")
const UIKit := preload("res://scripts/UIKit.gd")

@onready var quiz: Node2D = %Quiz
@onready var results: Node2D = %Results
@onready var header: Label = %Header
@onready var progress: Label = %Progress
@onready var icon: Sprite2D = %Icon
@onready var question_label: Label = %QuestionLabel
@onready var feedback: Label = %Feedback
@onready var next_button: Button = %NextButton
@onready var results_title: Label = %ResultsTitle
@onready var score_before: Label = %ScoreBefore
@onready var score_after: Label = %ScoreAfter
@onready var improvement: Label = %Improvement
@onready var result_message: Label = %ResultMessage
@onready var action_button: Button = %ActionButton
@onready var menu_button: Button = %MenuButton

var answer_buttons: Array = []

var _mode := "pre"
var _index := 0
var _score := 0
var _answered := false
var _answers: Array = [] # true/false por pregunta
var _summary: Control
var _option_map: Array = [] # índice original de la opción que muestra cada botón


func _ready() -> void:
	_mode = GameManager.trivia_mode
	GameManager.play_music("menu")
	answer_buttons = [%Answer1, %Answer2, %Answer3, %Answer4]
	for i in answer_buttons.size():
		answer_buttons[i].pressed.connect(_on_answer_pressed.bind(i))
	next_button.pressed.connect(_advance)
	action_button.pressed.connect(_on_action_pressed)
	menu_button.pressed.connect(_go_menu)

	results.visible = false
	quiz.visible = true
	if _mode == "pre":
		header.text = "TEST INICIAL: ¿QUÉ SABES DE HARDWARE?"
	else:
		header.text = "TEST FINAL: ¿QUÉ APRENDISTE?"
	_show_question()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _summary:
			_close_summary()
		else:
			_go_menu()
		return
	# Atajos 1-4 para responder.
	if quiz.visible and not _answered and event is InputEventKey and event.pressed and not event.echo:
		var slot := -1
		match event.physical_keycode:
			KEY_1: slot = 0
			KEY_2: slot = 1
			KEY_3: slot = 2
			KEY_4: slot = 3
		if slot >= 0:
			_on_answer_pressed(slot)


# ---------------------------------------------------------------- Preguntas
func _show_question() -> void:
	_answered = false
	var q: Dictionary = Data.QUESTIONS[_index]
	progress.text = "Pregunta %d / %d" % [_index + 1, Data.QUESTIONS.size()]
	var tex := load("res://assets/sprites/%s.png" % q["icon"]) as Texture2D
	icon.texture = tex
	icon.scale = Vector2.ONE * (3.0 if tex.get_width() <= 16 else 2.0)
	question_label.text = q["question"]
	feedback.text = ""
	next_button.visible = false

	# Las opciones se mezclan cada vez; se recuerda cuál es la correcta.
	_option_map = range(q["options"].size())
	_option_map.shuffle()
	for i in answer_buttons.size():
		var button: Button = answer_buttons[i]
		button.text = "%d)  %s" % [i + 1, q["options"][_option_map[i]]]
		button.modulate = Color.WHITE
	answer_buttons[0].grab_focus()


func _on_answer_pressed(slot: int) -> void:
	if _answered:
		return
	_answered = true
	var q: Dictionary = Data.QUESTIONS[_index]
	var correct_slot: int = _option_map.find(q["correct"])
	var is_correct := slot == correct_slot
	if is_correct:
		_score += 1
	_answers.append(is_correct)

	if _mode == "post":
		# En el test final sí se muestra el resultado y la explicación.
		for i in answer_buttons.size():
			if i == correct_slot:
				answer_buttons[i].modulate = Color(0.6, 1.0, 0.6)
			elif i == slot:
				answer_buttons[i].modulate = Color(1.0, 0.55, 0.55)
		feedback.text = ("¡Correcto! " if is_correct else "Incorrecto. ") + str(q["explanation"])
		GameManager.play_sfx("heal" if is_correct else "hit", -8.0)
		next_button.text = "SIGUIENTE" if _index < Data.QUESTIONS.size() - 1 else "VER RESULTADOS"
		next_button.visible = true
		next_button.grab_focus()
	else:
		GameManager.play_sfx("pickup", -8.0)
		_advance()


func _advance() -> void:
	_index += 1
	if _index >= Data.QUESTIONS.size():
		_finish()
	else:
		_show_question()


# ---------------------------------------------------------------- Resultados
func _finish() -> void:
	var total: int = Data.QUESTIONS.size()
	quiz.visible = false
	results.visible = true

	if _mode == "pre":
		GameManager.trivia_pre_score = _score
		GameManager.trivia_pre_answers = _answers.duplicate()
		results_title.text = "DIAGNÓSTICO INICIAL"
		score_before.text = "Aciertos: %d / %d" % [_score, total]
		score_after.visible = false
		improvement.visible = false
		result_message.text = "Ahora a jugar: recoge hardware, elimina virus y ensambla PCs.\nCada pieza que recojas te enseñará algo. Al final repetirás este test."
		action_button.text = "COMENZAR"
		menu_button.visible = false
	else:
		GameManager.trivia_post_score = _score
		GameManager.trivia_post_answers = _answers.duplicate()
		var pre := GameManager.trivia_pre_score
		results_title.text = "RESULTADOS DEL APRENDIZAJE"
		score_after.visible = true
		improvement.visible = true
		score_after.text = "Después de jugar: %d / %d" % [_score, total]
		if pre >= 0:
			score_before.text = "Antes de jugar: %d / %d" % [pre, total]
			var diff := _score - pre
			if diff > 0:
				improvement.text = "¡Mejoraste +%d respuesta(s)!" % diff
				result_message.text = "¡Aprendiste jugando! Cada pieza y cada virus te enseñó algo nuevo."
			elif diff == 0:
				improvement.text = "Mismo resultado que al inicio"
				result_message.text = "Repasa las definiciones de cada pieza y vuelve a intentarlo."
			else:
				improvement.text = "Bajaste %d respuesta(s)" % -diff
				result_message.text = "Vuelve a jugar prestando atención a los mensajes de cada pieza."
		else:
			score_before.text = "Antes de jugar: sin registro"
			improvement.text = ""
			result_message.text = "Para comparar, juega desde el menú principal (test inicial incluido)."
		action_button.text = "VER RESUMEN"
		menu_button.visible = true
	action_button.grab_focus()


func _on_action_pressed() -> void:
	if _mode == "pre":
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		_open_summary()


func _play_again() -> void:
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Trivia.tscn")


# ---------------------------------------------------------------- Resumen final
## Resumen para el estudiante y el docente: aciertos antes/después, temas
## dominados y por repasar (con recomendación) y estadísticas de la partida.
func _open_summary() -> void:
	results.visible = false
	_summary = Control.new()
	_summary.size = Vector2(640, 360)
	add_child(_summary)

	var frame := UIKit.panel(UIKit.BLUE, 10.0)
	frame.position = Vector2(20, 8)
	frame.custom_minimum_size = Vector2(600, 344)
	_summary.add_child(frame)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	frame.add_child(layout)

	var head := UIKit.label("RESUMEN DE APRENDIZAJE", 16, UIKit.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(head)

	var total: int = Data.QUESTIONS.size()
	var pre := GameManager.trivia_pre_score
	var post := GameManager.trivia_post_score
	var score_text := "Test:  antes %s  ->  después %d/%d" % [
		("%d/%d" % [pre, total]) if pre >= 0 else "sin registro", post, total]
	var score := UIKit.label(score_text, 12, UIKit.CYAN)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(score)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	layout.add_child(cols)

	# Columna izquierda: tema por tema.
	var topics := VBoxContainer.new()
	topics.add_theme_constant_override("separation", 2)
	topics.custom_minimum_size = Vector2(250, 0)
	cols.add_child(topics)
	topics.add_child(UIKit.label("TEMAS (antes / después)", 10, UIKit.GREY))
	var pre_answers := GameManager.trivia_pre_answers
	var post_answers := GameManager.trivia_post_answers
	var to_review: Array = []
	for i in total:
		var q: Dictionary = Data.QUESTIONS[i]
		var ok_post: bool = i < post_answers.size() and post_answers[i]
		var before := "-"
		if i < pre_answers.size():
			before = "SI" if pre_answers[i] else "NO"
		var line := UIKit.label("%s  %s   (%s / %s)" % ["[OK]" if ok_post else "[X] ", q["topic"], before, "SI" if ok_post else "NO"],
			10, UIKit.GREEN if ok_post else UIKit.RED)
		topics.add_child(line)
		if not ok_post:
			to_review.append(q)

	# Columna derecha: estadísticas de la partida.
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 2)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(stats)
	stats.add_child(UIKit.label("EN EL JUEGO", 10, UIKit.GREY))
	var rs: Dictionary = GameManager.run_stats
	var t: int = int(rs.get("time", 0.0))
	for text in [
		"PCs ensambladas: %d" % rs.get("pcs_built", 0),
		"Errores de orden al ensamblar: %d" % rs.get("assembly_errors", 0),
		"Virus eliminados: %d" % rs.get("kills", 0),
		"Vidas perdidas: %d" % rs.get("lives_lost", 0),
		"Tiempo de juego: %d:%02d" % [t / 60, t % 60],
		"Fichas en el álbum: %d / %d" % [_album_count(), UIKit.LearnData.ORDER.size()],
	]:
		stats.add_child(UIKit.label(text, 10))

	# Recomendaciones.
	layout.add_child(UIKit.label("RECOMENDACIÓN", 10, UIKit.GOLD))
	var advice := PackedStringArray()
	if to_review.is_empty():
		advice.append("¡Dominas todos los temas del test! Puedes intentar terminar con menos errores y vidas perdidas.")
	else:
		for q in to_review:
			advice.append("- " + str(q["review"]))
	if int(rs.get("assembly_errors", 0)) > 0:
		advice.append("- Orden de montaje: placa base -> CPU -> RAM -> disco.")
	var advice_label := UIKit.label("\n".join(advice), 10, Color.WHITE, true)
	advice_label.custom_minimum_size = Vector2(570, 0)
	layout.add_child(advice_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	layout.add_child(buttons)
	var again := UIKit.button("JUGAR DE NUEVO", 12)
	again.custom_minimum_size = Vector2(170, 24)
	again.pressed.connect(_play_again)
	buttons.add_child(again)
	var menu := UIKit.button("MENÚ", 12)
	menu.custom_minimum_size = Vector2(120, 24)
	menu.pressed.connect(_go_menu)
	buttons.add_child(menu)
	again.grab_focus()


func _album_count() -> int:
	var n := 0
	for id in UIKit.LearnData.ORDER:
		if GameManager.album.has(id):
			n += 1
	return n


func _close_summary() -> void:
	_summary.queue_free()
	_summary = null
	results.visible = true
	action_button.grab_focus()


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

extends Node2D
## Test de trivia. Se usa dos veces:
##   - "pre":  antes de jugar (diagnóstico, sin mostrar las respuestas correctas)
##   - "post": al ganar (muestra si acertaste y por qué) y compara con el pre-test.

const Data := preload("res://scripts/TriviaData.gd")

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
		results_title.text = "DIAGNÓSTICO INICIAL"
		score_before.text = "Aciertos: %d / %d" % [_score, total]
		score_after.visible = false
		improvement.visible = false
		result_message.text = "Ahora a jugar: recoge hardware, elimina virus y ensambla PCs.\nCada pieza que recojas te enseñará algo. Al final repetirás este test."
		action_button.text = "COMENZAR"
		menu_button.visible = false
	else:
		GameManager.trivia_post_score = _score
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
		action_button.text = "JUGAR DE NUEVO"
		menu_button.visible = true
	action_button.grab_focus()


func _on_action_pressed() -> void:
	if _mode == "pre":
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		GameManager.start_new_run()
		get_tree().change_scene_to_file("res://scenes/Trivia.tscn")


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

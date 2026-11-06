extends RefCounted
## Preguntas de la trivia (el MISMO test se usa antes y después de jugar).
## Para cambiar o añadir preguntas, edita esta lista. Cada pregunta necesita:
##   icon        -> sprite de assets/sprites (sin .png) que se muestra arriba
##   question    -> texto de la pregunta
##   options     -> exactamente 4 opciones
##   correct     -> índice (0-3) de la opción correcta en `options`
##   explanation -> se muestra en el test final para reforzar lo aprendido
##   topic       -> tema corto para el resumen final
##   review      -> qué repasar si se falla (aparece en el resumen final)
## Las respuestas se enseñan durante el juego: cada pieza recogida muestra su
## definición, y el jefe explica qué es el ransomware.

const QUESTIONS := [
	{
		"icon": "item_ram",
		"question": "¿Qué componente guarda datos de forma TEMPORAL mientras la computadora está encendida y trabajando?",
		"options": ["Memoria RAM", "Disco duro", "Placa base", "Procesador (CPU)"],
		"correct": 0,
		"explanation": "La RAM guarda temporalmente los datos y programas en uso. Al apagar el equipo, su contenido se borra.",
		"topic": "Memoria RAM",
		"review": "RAM = memoria TEMPORAL (se borra al apagar). Repasa su ficha en el álbum.",
	},
	{
		"icon": "item_cpu",
		"question": "¿Cuál es el «cerebro» de la computadora, el que ejecuta las instrucciones de los programas?",
		"options": ["Procesador (CPU)", "Memoria RAM", "Disco duro", "Teclado"],
		"correct": 0,
		"explanation": "La CPU interpreta y ejecuta las instrucciones. Su velocidad influye directamente en el rendimiento.",
		"topic": "Procesador (CPU)",
		"review": "La CPU es el «cerebro»: ejecuta las instrucciones. Repasa su ficha.",
	},
	{
		"icon": "item_board",
		"question": "¿Qué pieza conecta y comunica entre sí a todos los componentes de la PC?",
		"options": ["Placa base (motherboard)", "Disco duro", "Memoria RAM", "Monitor"],
		"correct": 0,
		"explanation": "La placa base es el circuito principal donde se conectan la CPU, la RAM, el disco y los demás componentes.",
		"topic": "Placa base",
		"review": "La placa base conecta todo; por eso se monta primero en la mesa.",
	},
	{
		"icon": "item_disk",
		"question": "¿Dónde se guardan tus archivos de forma PERMANENTE, incluso con el equipo apagado?",
		"options": ["Disco duro (o SSD)", "Memoria RAM", "Procesador (CPU)", "Placa base"],
		"correct": 0,
		"explanation": "El disco duro o SSD almacena el sistema, los programas y tus archivos de forma permanente.",
		"topic": "Almacenamiento (disco)",
		"review": "Disco/SSD = almacenamiento PERMANENTE. Compáralo con la RAM (temporal).",
	},
	{
		"icon": "boss",
		"question": "¿Cómo se llama el malware que «secuestra» tus archivos y exige un pago para devolverlos?",
		"options": ["Ransomware", "Adware", "Gusano", "Spyware"],
		"correct": 0,
		"explanation": "El ransomware cifra tus archivos y pide un rescate. Se previene con copias de seguridad y un antivirus actualizado.",
		"topic": "Malware (ransomware)",
		"review": "Repasa las fichas de malware: ransomware, troyano, gusano, adware y phishing.",
	},
]

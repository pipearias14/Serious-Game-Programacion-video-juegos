extends RefCounted
## Fichas educativas que se desbloquean en el juego y se guardan en el ÁLBUM.
##   - Hardware: al recoger la pieza por primera vez en la partida.
##   - Virus: al eliminar por primera vez cada tipo (y el jefe al aparecer).
## Para añadir una ficha, agrega una entrada aquí (id único) y llama a
## HUD.show_card(id) desde donde corresponda.

const ORDER := ["BOARD", "CPU", "RAM", "DISK", "WORM", "TROJAN", "RUNNER", "SPAMMER", "BOSS"]

const CARDS := {
	"BOARD": {
		"group": "HARDWARE", "icon": "item_board", "title": "Placa base (motherboard)",
		"what": "El circuito principal de la PC.",
		"use": "Conecta y comunica la CPU, la RAM, el disco y todo lo demás.",
		"fact": "Es lo primero que se monta: todas las demás piezas van conectadas a ella.",
	},
	"CPU": {
		"group": "HARDWARE", "icon": "item_cpu", "title": "Procesador (CPU)",
		"what": "El «cerebro» de la computadora.",
		"use": "Ejecuta las instrucciones de los programas, miles de millones por segundo.",
		"fact": "Se calienta mucho: por eso siempre lleva encima un disipador con ventilador.",
	},
	"RAM": {
		"group": "HARDWARE", "icon": "item_ram", "title": "Memoria RAM",
		"what": "Memoria de trabajo, rápida y TEMPORAL.",
		"use": "Guarda los datos y programas que estás usando en este momento.",
		"fact": "Al apagar la PC se borra todo lo que tenía. Más RAM = más programas abiertos a la vez.",
	},
	"DISK": {
		"group": "HARDWARE", "icon": "item_disk", "title": "Disco duro / SSD",
		"what": "El almacenamiento PERMANENTE.",
		"use": "Guarda el sistema operativo, los programas y tus archivos aunque apagues.",
		"fact": "Un SSD no tiene piezas móviles y puede ser más de 10 veces más rápido que un disco duro.",
	},
	"WORM": {
		"group": "MALWARE", "icon": "virus_worm", "title": "Gusano (worm)",
		"what": "Malware que se copia a sí mismo.",
		"use": "Se propaga solo de equipo en equipo por la red, sin que nadie lo abra.",
		"fact": "Mantén el sistema actualizado: así se cierran los huecos que usa para entrar.",
	},
	"TROJAN": {
		"group": "MALWARE", "icon": "virus_trojan", "title": "Troyano",
		"what": "Malware disfrazado de programa legítimo.",
		"use": "Te engaña para que lo instales y luego abre una «puerta trasera».",
		"fact": "Descarga programas solo de sitios oficiales (su nombre viene del caballo de Troya).",
	},
	"RUNNER": {
		"group": "MALWARE", "icon": "virus_runner", "title": "Adware",
		"what": "Software que llena tu equipo de anuncios.",
		"use": "Aparece de golpe y rápido, abre ventanas y puede espiar lo que navegas.",
		"fact": "Lee cada paso de los instaladores gratuitos y no aceptes programas extra.",
	},
	"SPAMMER": {
		"group": "MALWARE", "icon": "virus_spammer", "title": "Spam y phishing",
		"what": "Mensajes masivos no deseados.",
		"use": "Ataca de lejos con enlaces falsos para robar contraseñas (phishing).",
		"fact": "No abras enlaces de mensajes urgentes: ningún banco te pide la clave por correo.",
	},
	"BOSS": {
		"group": "MALWARE", "icon": "boss", "title": "Ransomware",
		"what": "Malware que «secuestra» tus archivos.",
		"use": "Los cifra y pide un rescate (dinero) para devolverlos.",
		"fact": "Haz copias de seguridad frecuentes y mantén el antivirus actualizado.",
	},
}

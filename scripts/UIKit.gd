extends RefCounted
## Utilidades para construir interfaz desde código con el mismo estilo del HUD
## (fichas educativas, álbum, mesa de ensamblaje y resumen final).

const LearnData := preload("res://scripts/LearnData.gd")

const BG := Color(0.101961, 0.109804, 0.172549, 0.96)
const BLUE := Color(0.254902, 0.65098, 0.964706, 1)
const CYAN := Color(0.45098, 0.937255, 0.968627, 1)
const GOLD := Color(1, 0.803922, 0.458824, 1)
const GREEN := Color(0.654902, 0.941176, 0.439216, 1)
const RED := Color(0.94, 0.45, 0.5, 1)
const GREY := Color(0.580392, 0.690196, 0.760784, 1)


static func panel_style(border: Color = BLUE, margin: float = 6.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.set_content_margin_all(margin)
	return sb


static func panel(border: Color = BLUE, margin: float = 6.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(border, margin))
	return p


static func label(text: String, size: int = 10, color: Color = Color.WHITE, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, size: int = 12) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.235294, 0.341176, 1)
	normal.set_border_width_all(2)
	normal.border_color = GREY
	normal.set_content_margin_all(4)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.231373, 0.364706, 0.788235, 1)
	hover.border_color = CYAN
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(3)
	focus.border_color = GOLD
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", focus)
	return b


static func icon(texture_name: String, size: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://assets/sprites/%s.png" % texture_name) as Texture2D
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t


## Contenido de una ficha: icono + título + qué es / para qué sirve / dato curioso.
static func card_body(card_id: String, width: float, is_new := false) -> VBoxContainer:
	var data: Dictionary = LearnData.CARDS[card_id]
	var malware: bool = data["group"] == "MALWARE"
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(width, 0)
	box.add_theme_constant_override("separation", 3)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.add_child(icon(data["icon"], 32))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	var tag := ("¡NUEVA FICHA!  " if is_new else "") + ("MALWARE" if malware else "HARDWARE")
	titles.add_child(label(tag, 8, RED if malware else GREEN))
	var t := label(data["title"], 12, GOLD, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.custom_minimum_size = Vector2(width - 38, 0)
	titles.add_child(t)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	box.add_child(head)

	box.add_child(_field("Qué es:", data["what"], width))
	box.add_child(_field("Qué hace:" if malware else "Para qué sirve:", data["use"], width))
	box.add_child(_field("Dato:" if not malware else "Cómo protegerte:", data["fact"], width))
	return box


## La anchura mínima fija hace que el texto se ajuste con la altura correcta.
static func _field(title: String, text: String, width: float) -> Label:
	var l := label("%s %s" % [title, text], 9, Color.WHITE, true)
	l.custom_minimum_size = Vector2(width, 0)
	return l

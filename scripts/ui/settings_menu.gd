extends CanvasLayer
## Basit ayar menuesu: Kalite (Dusuk/Orta/Yuksek), dil, gunun saati, FPS.
## Sol ustteki butonla acilir/kapanir. Mobil dokunmatik icin buyuk hedefler.

const PANEL_WIDTH := 440

var _root: Control
var _open: bool = false
var _quality_buttons: Array[Button] = []
var _title: Label
var _lbl_quality: Label
var _lbl_hint: Label
var _lbl_time: Label
var _lbl_fps: Label
var _lbl_lang: Label
var _close_btn: Button
var _lang_btn: Button
var _fps_label: Label
var _fps_accum: float = 0.0
var _fps_frames: int = 0
var _fps_value: float = 0.0


func _ready() -> void:
	layer = 10
	_build_ui()
	_refresh_texts()
	if I18N != null:
		I18N.lang = I18N.lang
	QualitySettings.quality_changed.connect(_on_quality_changed)


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# --- Ayar butonu (sol ust) ---
	var gear := Button.new()
	gear.text = "⚙"
	gear.name = "GearButton"
	gear.add_theme_font_size_override("font_size", 34)
	gear.custom_minimum_size = Vector2(72, 72)
	gear.position = Vector2(18, 18)
	gear.tooltip_text = "Ayarlar"
	gear.pressed.connect(toggle)
	_root.add_child(gear)

	# --- Panel ---
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(18, 102)
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.visible = false
	_root.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.13, 0.18, 0.92)
	style.border_color = Color(1.0, 0.93, 0.78, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_title = _make_label("", 30)
	vbox.add_child(_title)

	vbox.add_child(_make_separator())

	_lbl_quality = _make_label("", 22)
	vbox.add_child(_lbl_quality)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)
	for i in 3:
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(118, 64)
		b.add_theme_font_size_override("font_size", 21)
		b.pressed.connect(_on_quality_pressed.bind(i))
		hbox.add_child(b)
		_quality_buttons.append(b)

	_lbl_hint = _make_label("", 16, Color(0.78, 0.82, 0.9))
	vbox.add_child(_lbl_hint)

	vbox.add_child(_make_separator())

	_lbl_time = _make_label("", 20)
	vbox.add_child(_lbl_time)

	_lbl_lang = _make_label("", 20)
	vbox.add_child(_lbl_lang)

	_lang_btn = Button.new()
	_lang_btn.custom_minimum_size = Vector2(0, 58)
	_lang_btn.add_theme_font_size_override("font_size", 20)
	_lang_btn.pressed.connect(_on_lang_pressed)
	vbox.add_child(_lang_btn)

	vbox.add_child(_make_separator())

	_fps_label = _make_label("", 20, Color(0.72, 0.92, 0.72))
	vbox.add_child(_fps_label)

	_close_btn = Button.new()
	_close_btn.custom_minimum_size = Vector2(0, 62)
	_close_btn.add_theme_font_size_override("font_size", 22)
	_close_btn.pressed.connect(toggle)
	vbox.add_child(_close_btn)


func _make_label(text: String, size: int, color: Color = Color(1, 1, 1)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PANEL_WIDTH - 46, 0)
	return l


func _make_separator() -> Control:
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.12)
	line.custom_minimum_size = Vector2(0, 2)
	return line


func toggle() -> void:
	_open = not _open
	var panel := _root.get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = _open


func _on_quality_pressed(level: int) -> void:
	QualitySettings.set_level(level)


func _on_quality_changed(_level: int) -> void:
	_refresh_texts()


func _on_lang_pressed() -> void:
	if I18N != null:
		I18N.toggle_lang()
	_refresh_texts()


func _refresh_texts() -> void:
	var lang := I18N.lang if I18N != null else "tr"
	_title.text = I18N.get_string("settings") if I18N != null else "Ayarlar"
	_lbl_quality.text = I18N.get_string("quality")
	_lbl_hint.text = I18N.get_string("quality_hint")
	_lbl_time.text = I18N.get_string("time_of_day")
	_lbl_lang.text = I18N.get_string("language")
	_lbl_fps.text = I18N.get_string("fps")
	_close_btn.text = I18N.get_string("close")

	var names := ["quality_low", "quality_medium", "quality_high"]
	for i in _quality_buttons.size():
		_quality_buttons[i].text = I18N.get_string(names[i])
		_quality_buttons[i].button_pressed = (i == QualitySettings.level)

	_lang_btn.text = "Türkçe" if lang == "tr" else "English"


func _process(delta: float) -> void:
	# FPS olcumu (sadece menu acikken gerekli ama hafif).
	_fps_accum += delta
	_fps_frames += 1
	if _fps_accum >= 0.5:
		_fps_value = float(_fps_frames) / _fps_accum
		_fps_accum = 0.0
		_fps_frames = 0
		var sky := get_tree().get_first_node_in_group("sky_cycle")
		var phase_txt := ""
		if sky != null and I18N != null:
			phase_txt = I18N.phase_name(sky.get("phase"))
		_fps_label.text = "%s: %.0f FPS    %s" % [
			I18N.get_string("fps") if I18N != null else "FPS",
			_fps_value,
			phase_txt,
		]

extends CanvasLayer
class_name PauseMenu

signal resume_requested
signal menu_requested
signal quit_requested

var _visible_panel: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10

	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.72)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	_visible_panel = panel

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_spacer(12))
	vbox.add_child(_make_btn("▶  Resume", resume_requested))
	vbox.add_child(_make_btn("⌂  Main Menu", menu_requested))
	vbox.add_child(_make_btn("✕  Quit", quit_requested))

	hide()

func _make_btn(label: String, sig: Signal) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(240, 52)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): sig.emit())
	return btn

func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

func open() -> void:
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false

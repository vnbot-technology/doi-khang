extends Control

var _main_panel: VBoxContainer
var _sub_panel: VBoxContainer
var _sub_label: Label

func _ready() -> void:
	MusicManager.play_menu()
	_build_title()
	_build_main()
	_build_sub()
	_show_main()

# ── Title ──────────────────────────────────────────────────────────────────

func _build_title() -> void:
	var title := Label.new()
	title.text = "DOI KHANG"
	title.position = Vector2(440, 150)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0.8, 0.2, 0.0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Anime Fighting Game"
	subtitle.position = Vector2(490, 222)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	add_child(subtitle)

# ── Main menu ──────────────────────────────────────────────────────────────

func _build_main() -> void:
	_main_panel = VBoxContainer.new()
	_main_panel.position = Vector2(490, 270)
	_main_panel.add_theme_constant_override("separation", 14)
	add_child(_main_panel)

	_add_btn(_main_panel, "[ PvP ]",    func(): _show_sub("pvp"))
	_add_btn(_main_panel, "[ vs AI ]",  func(): _show_sub("ai"))
	_add_btn(_main_panel, "[ Online ]", func(): _show_sub("online"))
	_add_btn(_main_panel, "Quit",       get_tree().quit)

# ── Sub-mode panel (slides in after category choice) ───────────────────────

func _build_sub() -> void:
	_sub_panel = VBoxContainer.new()
	_sub_panel.position = Vector2(490, 240)
	_sub_panel.add_theme_constant_override("separation", 14)
	add_child(_sub_panel)

	_sub_label = Label.new()
	_sub_label.add_theme_font_size_override("font_size", 22)
	_sub_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.custom_minimum_size = Vector2(300, 36)
	_sub_panel.add_child(_sub_label)

	_sub_panel.add_child(_spacer(8))
	# Filled dynamically in _show_sub()

func _show_sub(category: String) -> void:
	Global.mode_category = category
	_main_panel.visible = false

	# Clear old sub-buttons (keep label + spacer = first 2 children)
	while _sub_panel.get_child_count() > 2:
		_sub_panel.get_child(_sub_panel.get_child_count() - 1).queue_free()

	if category == "pvp":
		_sub_label.text = "[ PvP ] — Choose mode"
		_add_btn(_sub_panel, "1 vs 1",      func(): _go_select("1v1"))
		_add_btn(_sub_panel, "2 vs 2",      func(): _go_select("2v2"))
	elif category == "ai":
		_sub_label.text = "[ vs AI ] — Choose mode"
		_add_btn(_sub_panel, "1 vs AI",     func(): _go_select("1vAI"))
		_add_btn(_sub_panel, "2 vs AI",     func(): _go_select("2vAI"))
	else:  # online
		_sub_label.text = "[ Online ] — Choose mode"
		_add_btn(_sub_panel, "1 vs 1",      func(): _go_lobby("1v1"))
		_add_btn(_sub_panel, "2 vs 2",      func(): _go_lobby("2v2"))

	_add_btn(_sub_panel, "< Back", _show_main)
	_sub_panel.visible = true

func _show_main() -> void:
	_sub_panel.visible = false
	_main_panel.visible = true

# ── Navigation ─────────────────────────────────────────────────────────────

func _go_select(submode: String) -> void:
	Global.mode_submode = submode
	Global.is_network_game = false
	Global.go_to_scene("res://scenes/CharacterSelect.tscn")

func _go_lobby(submode: String) -> void:
	Global.mode_submode = submode
	Global.is_network_game = true
	Global.go_to_scene("res://scenes/LobbyRoom.tscn")

func _on_online() -> void:
	_show_sub("online")

# ── Helpers ────────────────────────────────────────────────────────────────

func _add_btn(parent: Control, label: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(300, 55)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(cb)
	parent.add_child(btn)
	return btn

func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

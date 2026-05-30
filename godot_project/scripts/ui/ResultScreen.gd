extends Control

# Built entirely programmatically so we don't depend on a specific
# ResultScreen.tscn node structure. Any matching @onready paths in the
# scene would silently fail if the tree was edited — this approach is robust.

func _ready() -> void:
	MusicManager.play_result()
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var winner_label := Label.new()
	winner_label.text = "PLAYER %d WINS!" % Global.last_winner if Global.last_winner > 0 else "DRAW!"
	winner_label.position = Vector2(440, 260)
	winner_label.add_theme_font_size_override("font_size", 52)
	winner_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	add_child(winner_label)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(490, 380)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	var rematch_btn := Button.new()
	rematch_btn.text = "REMATCH"
	rematch_btn.custom_minimum_size = Vector2(300, 60)
	rematch_btn.add_theme_font_size_override("font_size", 24)
	rematch_btn.pressed.connect(func(): Global.go_to_scene("res://scenes/GameArena.tscn"))
	vbox.add_child(rematch_btn)

	var menu_btn := Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(300, 60)
	menu_btn.add_theme_font_size_override("font_size", 24)
	menu_btn.pressed.connect(func(): Global.go_to_scene("res://scenes/MainMenu.tscn"))
	vbox.add_child(menu_btn)

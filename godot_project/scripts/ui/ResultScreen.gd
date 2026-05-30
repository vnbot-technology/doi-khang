extends Control

@onready var winner_label: Label = $WinnerLabel
@onready var rematch_btn: Button = $Buttons/RematchBtn
@onready var menu_btn: Button = $Buttons/MenuBtn

func _ready() -> void:
	MusicManager.play_result()
	winner_label.text = "PLAYER %d WINS!" % Global.last_winner
	rematch_btn.pressed.connect(func(): Global.go_to_scene("res://scenes/GameArena.tscn"))
	menu_btn.pressed.connect(func(): Global.go_to_scene("res://scenes/MainMenu.tscn"))

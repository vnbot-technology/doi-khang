extends Control

func _ready() -> void:
	$VBox/PlayLocalBtn.pressed.connect(_on_local)
	$VBox/PlayLANBtn.pressed.connect(_on_lan)
	$VBox/PlayInternetBtn.pressed.connect(_on_internet)
	$VBox/QuitBtn.pressed.connect(get_tree().quit)

func _on_local() -> void:
	Global.is_network_game = false
	Global.go_to_scene("res://scenes/CharacterSelect.tscn")

func _on_lan() -> void:
	Global.is_network_game = true
	NetworkManager.connection_type = "lan"
	Global.go_to_scene("res://scenes/CharacterSelect.tscn")

func _on_internet() -> void:
	Global.is_network_game = true
	NetworkManager.connection_type = "internet"
	Global.go_to_scene("res://scenes/CharacterSelect.tscn")

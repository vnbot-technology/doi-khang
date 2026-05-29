extends Control

func _ready() -> void:
	$VBox/PlayLocalBtn.pressed.connect(_on_local)
	$VBox/PlayLANBtn.pressed.connect(_on_lan)
	$VBox/PlayInternetBtn.pressed.connect(_on_internet)
	# Use a Callable explicitly: get_tree().quit is a Callable in Godot 4, but
	# wrapping in a lambda keeps the signal-connect semantics unambiguous and
	# protects against get_tree() returning null at connect time.
	$VBox/QuitBtn.pressed.connect(_on_quit)

func _on_quit() -> void:
	get_tree().quit()

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

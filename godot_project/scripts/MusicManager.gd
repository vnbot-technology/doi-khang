extends Node

# Battle Stadium D.O.N. OST — track assignments
# Tracks 00-02: short jingles   | 03-18: full themes   | 19-28: short cues

const MENU_TRACKS:    Array[String] = [
	"res://assets/music/track_04.mp3",
	"res://assets/music/track_05.mp3",
]
const BATTLE_TRACKS:  Array[String] = [
	"res://assets/music/track_06.mp3",
	"res://assets/music/track_07.mp3",
	"res://assets/music/track_08.mp3",
	"res://assets/music/track_09.mp3",
	"res://assets/music/track_10.mp3",
	"res://assets/music/track_11.mp3",
	"res://assets/music/track_12.mp3",
	"res://assets/music/track_13.mp3",
	"res://assets/music/track_14.mp3",
	"res://assets/music/track_15.mp3",
	"res://assets/music/track_16.mp3",
	"res://assets/music/track_17.mp3",
	"res://assets/music/track_18.mp3",
]
const VICTORY_TRACK:  String = "res://assets/music/track_19.mp3"
const RESULT_TRACK:   String = "res://assets/music/track_20.mp3"

var _player: AudioStreamPlayer
var _current_path: String = ""
var _should_loop: bool = false

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = -6.0
	add_child(_player)
	_player.finished.connect(_on_finished)

func play_menu() -> void:
	var track := MENU_TRACKS[randi() % MENU_TRACKS.size()]
	_play(track, true)

func play_battle() -> void:
	var track := BATTLE_TRACKS[randi() % BATTLE_TRACKS.size()]
	_play(track, true)

func play_victory() -> void:
	_play(VICTORY_TRACK, false)

func play_result() -> void:
	_play(RESULT_TRACK, true)

func stop() -> void:
	_player.stop()
	_current_path = ""
	_should_loop = false

func set_volume(db: float) -> void:
	_player.volume_db = db

func get_volume() -> float:
	return _player.volume_db

func _play(path: String, loop: bool) -> void:
	if path == _current_path and _player.playing:
		return
	_current_path = path
	_should_loop = loop
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	_player.stream = stream
	_player.play()

func _on_finished() -> void:
	# MP3 tracks loop via AudioStreamMP3.loop, so this rarely fires for them.
	# Kept as a safety net for any non-looping stream type that should repeat.
	if _current_path != "" and _should_loop:
		_player.play()

extends Node

# Sound pools from Naruto: Ninja Council GBA sound rip.
# Files are named song001-song099 (some numbers skipped).
# Categories are assigned by file size / approximate content:
#   Impact/UI (smallest, <100KB): short sfx — hits, select, etc.
#   Attack (~92-163KB): punch/kick/swing sounds
#   Jump (~71KB): movement sounds
#   Block (~41KB): guard clank sounds
#   Hurt/Damage (~184KB): reaction sounds
#   Special (~122-225KB): chakra / technique sounds
#   Ultimate (~297-522KB): longer dramatic sounds
#   Death (~297KB+): KO sounds

const _SFX_DIR := "res://assets/sfx/"

const _IMPACT_POOL  := ["song001","song003","song006","song010","song022","song061","song067","song068","song072","song074"]
const _ATTACK_POOL  := ["song009","song019","song034","song035","song062","song064","song069","song073","song082"]
const _JUMP_POOL    := ["song004","song013"]
const _BLOCK_POOL   := ["song007","song014"]
const _HURT_POOL    := ["song016","song065","song092","song097"]
const _SPECIAL_POOL := ["song002","song005","song015","song091","song024","song057","song088"]
const _ULTIMATE_POOL:= ["song020","song023","song028","song029","song030","song031","song056"]
const _DEATH_POOL   := ["song018","song080","song089","song093"]
const _WIN_POOL     := ["song025","song026","song058","song085"]

# Per-character voice mapping.
# Each entry maps event names to a list of song filenames (without .wav).
# Characters not listed here will use generic pools above.
# Fill these in by listening to the files and assigning the right ones.
const CHARACTER_VOICES: Dictionary = {
	"Naruto": {
		"attack":  ["song021"],
		"hurt":    ["song022"],
		"special": ["song023"],
		"ultimate":["song025"],
		"death":   ["song027"],
	},
	"Sasuke": {
		"attack":  ["song032"],
		"hurt":    ["song033"],
		"special": ["song056"],
		"ultimate":["song059"],
		"death":   ["song060"],
	},
	"Sakura": {
		"attack":  ["song066"],
		"hurt":    ["song067"],
		"special": ["song070"],
		"ultimate":["song071"],
		"death":   ["song075"],
	},
	"Kakashi": {
		"attack":  ["song077"],
		"hurt":    ["song078"],
		"special": ["song079"],
		"ultimate":["song081"],
		"death":   ["song083"],
	},
	"Rock Lee": {
		"attack":  ["song084"],
		"hurt":    ["song085"],
		"special": ["song086"],
		"ultimate":["song087"],
		"death":   ["song089"],
	},
	"Neji": {
		"attack":  ["song090"],
		"hurt":    ["song091"],
		"special": ["song094"],
		"ultimate":["song095"],
		"death":   ["song096"],
	},
}

const _SFX_POOL_SIZE := 6

var _sfx_players: Array = []  # AudioStreamPlayer[]
var _voice_player: AudioStreamPlayer

var _sfx_enabled: bool = true
var _voice_enabled: bool = true

func _ready() -> void:
	for i in _SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -10.0
		add_child(p)
		_sfx_players.append(p)
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Master"
	_voice_player.volume_db = -6.0
	add_child(_voice_player)

# ── Public API ─────────────────────────────────────────────────────────────

func play_hit() -> void:
	_play_sfx(_pick(_IMPACT_POOL))

func play_attack(char_name: String = "") -> void:
	var voice := _char_voice(char_name, "attack")
	if voice:
		_play_voice(voice)
	_play_sfx(_pick(_ATTACK_POOL))

func play_jump() -> void:
	_play_sfx(_pick(_JUMP_POOL))

func play_block() -> void:
	_play_sfx(_pick(_BLOCK_POOL))

func play_hurt(char_name: String = "") -> void:
	var voice := _char_voice(char_name, "hurt")
	if voice:
		_play_voice(voice)
	_play_sfx(_pick(_HURT_POOL))

func play_special(char_name: String = "") -> void:
	var voice := _char_voice(char_name, "special")
	if voice:
		_play_voice(voice)
	_play_sfx(_pick(_SPECIAL_POOL))

func play_ultimate(char_name: String = "") -> void:
	var voice := _char_voice(char_name, "ultimate")
	if voice:
		_play_voice(voice)
	_play_sfx(_pick(_ULTIMATE_POOL))

func play_death(char_name: String = "") -> void:
	var voice := _char_voice(char_name, "death")
	if voice:
		_play_voice(voice)
	_play_sfx(_pick(_DEATH_POOL))

func play_win(char_name: String = "") -> void:
	_play_sfx(_pick(_WIN_POOL))

# ── Internals ───────────────────────────────────────────────────────────────

func _char_voice(char_name: String, event: String) -> String:
	if char_name.is_empty() or not CHARACTER_VOICES.has(char_name):
		return ""
	var voices: Array = CHARACTER_VOICES[char_name].get(event, [])
	if voices.is_empty():
		return ""
	return _SFX_DIR + voices[randi() % voices.size()] + ".wav"

func _pick(pool: Array) -> String:
	return _SFX_DIR + pool[randi() % pool.size()] + ".wav"

func _play_sfx(path: String) -> void:
	if not _sfx_enabled:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	for p in _sfx_players:
		var player := p as AudioStreamPlayer
		if not player.playing:
			player.stream = stream
			player.play()
			return
	var first := _sfx_players[0] as AudioStreamPlayer
	first.stream = stream
	first.play()

func _play_voice(path: String) -> void:
	if not _voice_enabled:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_voice_player.stream = stream
	_voice_player.play()

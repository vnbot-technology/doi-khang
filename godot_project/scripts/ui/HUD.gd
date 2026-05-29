extends CanvasLayer
class_name HUD

@onready var p1_hp_bar: ProgressBar = $P1Side/P1Info/HPBar
@onready var p1_sp_bar: ProgressBar = $P1Side/P1Info/SPBar
@onready var p1_name_label: Label = $P1Side/P1Info/CharName
@onready var p2_hp_bar: ProgressBar = $P2Side/P2Info/HPBar
@onready var p2_sp_bar: ProgressBar = $P2Side/P2Info/SPBar
@onready var p2_name_label: Label = $P2Side/P2Info/CharName
@onready var timer_label: Label = $CenterPanel/TimerLabel
@onready var round_label: Label = $CenterPanel/RoundLabel
@onready var announce_label: Label = $CenterPanel/AnnounceLabel
@onready var p1_win_dots: HBoxContainer = $P1Side/P1Info/WinDots
@onready var p2_win_dots: HBoxContainer = $P2Side/P2Info/WinDots

func setup_players(p1: CharacterBase, p2: CharacterBase) -> void:
	p1_name_label.text = p1.char_name
	p2_name_label.text = p2.char_name
	p1_hp_bar.max_value = p1.max_health
	p1_hp_bar.value = p1.health
	p1_sp_bar.max_value = p1.max_special
	p1_sp_bar.value = 0.0
	p2_hp_bar.max_value = p2.max_health
	p2_hp_bar.value = p2.health
	p2_sp_bar.max_value = p2.max_special
	p2_sp_bar.value = 0.0
	p1.health_changed.connect(func(hp: float, _mx: float): p1_hp_bar.value = hp)
	p1.special_changed.connect(func(sp: float): p1_sp_bar.value = sp)
	p2.health_changed.connect(func(hp: float, _mx: float): p2_hp_bar.value = hp)
	p2.special_changed.connect(func(sp: float): p2_sp_bar.value = sp)

func update_timer(seconds: float) -> void:
	timer_label.text = "%02d" % int(ceil(seconds))
	timer_label.modulate = Color.RED if seconds <= 10.0 else Color.WHITE

func show_round(num: int) -> void:
	round_label.text = "ROUND %d" % num
	announce("ROUND %d" % num)

func announce(text: String, duration: float = 1.5) -> void:
	announce_label.text = text
	announce_label.visible = true
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(announce_label):
			announce_label.visible = false
	)

func update_wins(p1_count: int, p2_count: int) -> void:
	_update_win_dots(p1_win_dots, p1_count)
	_update_win_dots(p2_win_dots, p2_count)

func _update_win_dots(container: HBoxContainer, count: int) -> void:
	for i in range(container.get_child_count()):
		var dot := container.get_child(i) as ColorRect
		if dot:
			dot.color = Color.YELLOW if i < count else Color(0.2, 0.2, 0.2)

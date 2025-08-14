extends Control

signal confirm_pressed
signal cancel_pressed

const _total_points = 15
var _phy = 3
var _men = 3
var _hea = 3
var _sex = 0.0
var _first_name = ""

var _name_data = preload("res://JSON/NPC/Last_Names_Male_Female_First_Names.json").data

func _ready():
	_update_controls()

func _update_controls():
	$PHY.text = str(_phy)
	$MEN.text = str(_men)
	$HEA.text = str(_hea)
	_update_remaining()
	$SliderBg/HSlider.value = _sex
	$Character_Name.text = _first_name
	_enable_disable_ok_button()

func _points_remaining():
	return _total_points - (_phy + _men + _hea)

func _update_phy(add: int = 0):
	if add <= 0 or _points_remaining() >= add:
		_phy = clampi(_phy + add, 3, 7)
		$PHY.text = str(_phy)
		_update_remaining()

func _update_men(add: int = 0):
	if add <= 0 or _points_remaining() >= add:
		_men = clampi(_men + add, 3, 7)
		$MEN.text = str(_men)
		_update_remaining()

func _update_hea(add: int = 0):
	if add <= 0 or _points_remaining() >= add:
		_hea = clampi(_hea + add, 3, 7)
		$HEA.text = str(_hea)
		_update_remaining()

func _update_remaining():
	$Remaining_Points.text = str(_total_points - (_phy + _men + _hea))
	_enable_disable_ok_button()

func _on_cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	cancel_pressed.emit()

func _on_any_button_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()
	
func _on_any_button_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_h_slider_value_changed(value: float):
	$Sex_Choice.pitch_scale = lerp(0.5, 0.505, value)

func _on_h_slider_drag_started():
	$Sex_Choice.play()

func _on_h_slider_drag_ended(_value_changed):
	$Sex_Choice.stop()

func _on_phy_moins_pressed():
	Globals.cancel_sound.play()
	_update_phy(-1)

func _on_phy_plus_pressed():
	Globals.valid_sound.play()
	if _points_remaining() > 0:
		_update_phy(1)

func _on_men_moins_pressed():
	Globals.cancel_sound.play()
	_update_men(-1)

func _on_men_plus_pressed():
	Globals.valid_sound.play()
	if _points_remaining() > 0:
		_update_men(1)

func _on_hea_moins_pressed():
	Globals.cancel_sound.play()
	_update_hea(-1)

func _on_hea_plus_pressed():
	Globals.valid_sound.play()
	if _points_remaining() > 0:
		_update_hea(1)

func _on_randomize_pressed():
	Globals.valid_sound.play()
	$Background_Selector/Background_List.randomize()
	_phy = randi_range(3, 7)
	var min_men = maxi(3, _total_points - _phy - 7)
	var max_men = mini(7, _total_points - _phy - 3)
	_men = randi_range(min_men, max_men)
	_hea = _total_points - _phy - _men
	var name_key
	if randi() & 1:
		_sex = 100.0
		name_key = "female_first_name"
	else:
		_sex = 0.0
		name_key = "male_first_name"
	_first_name = _name_data[name_key].pick_random()
	_update_controls()

func _on_reset_pressed():
	Globals.cancel_sound.play()
	$Background_Selector/Background_List.reset()
	_phy = 3
	_men = 3
	_hea = 3
	_update_controls()

func _on_background_list_item_selected():
	Globals.valid_sound.play()
	$Story.text = $Background_Selector/Background_List.get_background_story()
	_enable_disable_ok_button()

func _enable_disable_ok_button():
	$Confirm.disabled = (
		_points_remaining() > 0 or
		$Character_Name.text.strip_edges().is_empty() or
		$Background_Selector/Background_List.get_background_story().is_empty())

func _on_confirm_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	var player = GameState.player
	var bg = $Background_Selector/Background_List.get_background()
	player.reset()
	player.player_name = $Character_Name.text.strip_edges()
	player.sex = $SliderBg/HSlider.value / 100.0
	player.job_id = bg.id
	player.job_name = bg.profession
	player.job_bonus_malus = bg.bonus_malus
	player.physical = _phy
	player.mental = _men
	player.max_health = _hea
	confirm_pressed.emit()

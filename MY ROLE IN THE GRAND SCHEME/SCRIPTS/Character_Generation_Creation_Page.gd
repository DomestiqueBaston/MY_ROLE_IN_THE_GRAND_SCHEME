extends Control

signal confirm_pressed
signal cancel_pressed

const _total_points = 15
var _phy = 3
var _men = 3
var _hea = 3

func _ready():
	_update_count_controls()

func _update_count_controls():
	$PHY.text = str(_phy)
	$MEN.text = str(_men)
	$HEA.text = str(_hea)
	_update_remaining()

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
	var pitch = lerp(0.5, 0.504, value)
	$Sex_Choice.pitch_scale = pitch
	if not $Sex_Choice.playing:
		$Sex_Choice.play()

func _input(event: InputEvent):
	if event.is_action_released("Left_Click"):
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
	_men = randi_range(3, mini(7, _total_points - _phy - 3))
	_hea = _total_points - _phy - _men
	_update_count_controls()

func _on_reset_pressed():
	Globals.cancel_sound.play()
	$Background_Selector/Background_List.reset()
	_phy = 3
	_men = 3
	_hea = 3
	_update_count_controls()

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
	Player.reset()
	Player.player_name = $Character_Name.text.strip_edges()
	Player.sex = $SliderBg/HSlider.value / 100.0
	Player.background = $Background_Selector/Background_List.get_background()
	Player.physical = _phy
	Player.mental = _men
	Player.max_health = _hea
	Player.start_game()
	confirm_pressed.emit()

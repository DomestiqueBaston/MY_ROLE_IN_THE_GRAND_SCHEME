extends Node2D

signal done

@onready var _volume_sliders = {
	$Buttons_Sliders/Sliders/Master:	&"Master",
	$Buttons_Sliders/Sliders/Music:		&"MUSIC",
	$Buttons_Sliders/Sliders/FX:		&"FX",
	$Buttons_Sliders/Sliders/UI:		&"UI",
	$Buttons_Sliders/Sliders/Ambiance:	&"AMBIANCE",
	$Buttons_Sliders/Sliders/Video:		&"VIDEO"
}

@onready var _difficulty_slider: Slider = $Buttons_Sliders/Sliders/Difficulty
@onready var _drug_quality_button: BaseButton = $Buttons_Sliders/Buttons/Drug_Quality
@onready var _plot_depth_button: BaseButton = $Buttons_Sliders/Buttons/Plot_Depth
@onready var _corruption_button: BaseButton = $Buttons_Sliders/Buttons/Corruption
@onready var _inflation_button: BaseButton = $Buttons_Sliders/Buttons/Retail_Investment
@onready var _vice_button: BaseButton = $Buttons_Sliders/Buttons/Vice
@onready var _liars_button: BaseButton = $Buttons_Sliders/Buttons/Mentirosos
@onready var _hardboiled_minions_button: BaseButton = $Buttons_Sliders/Buttons/Hardboiled_Minions
@onready var _no_public_medicine_button: BaseButton = $Buttons_Sliders/Buttons/No_Public_Docs

var _initial_volumes: Array[float]
var _confirmed: bool

func _ready():
	var sliders = _volume_sliders.keys()
	var bus_names = _volume_sliders.values()
	for i in _volume_sliders.size():
		var volume = Globals.get_volume(bus_names[i])
		_initial_volumes.append(volume)
		sliders[i].value = volume * 100.0
		sliders[i].value_changed.connect(_on_volume_changed.bind(i))
	_difficulty_slider.value = Globals.game_difficulty
	_drug_quality_button.button_pressed = Globals.drug_quality_flag
	_plot_depth_button.button_pressed = Globals.plot_depth_flag
	_corruption_button.button_pressed = Globals.corruption_flag
	_inflation_button.button_pressed = Globals.inflation_flag
	_vice_button.button_pressed = Globals.vice_flag
	_liars_button.button_pressed = Globals.liars_flag
	_hardboiled_minions_button.button_pressed = Globals.hardboiled_minions_flag
	_no_public_medicine_button.button_pressed = Globals.no_public_medicine_flag

	$Buttons_Sliders/Ok_Cancel_Reset_Buttons/Ok.pressed.connect(_on_ok)
	$Buttons_Sliders/Ok_Cancel_Reset_Buttons/Cancel.pressed.connect(_on_cancel)
	$Buttons_Sliders/Ok_Cancel_Reset_Buttons/Reset.pressed.connect(_on_reset)

func _on_volume_changed(value: float, index: int):
	var bus_name = _volume_sliders.values()[index]
	Globals.set_volume(bus_name, value / 100.0)

func _on_ok():
	_confirmed = true
	Globals.game_difficulty = int(_difficulty_slider.value)
	Globals.drug_quality_flag = _drug_quality_button.button_pressed
	Globals.plot_depth_flag = _plot_depth_button.button_pressed
	Globals.corruption_flag = _corruption_button.button_pressed
	Globals.inflation_flag = _inflation_button.button_pressed
	Globals.vice_flag = _vice_button.button_pressed
	Globals.liars_flag = _liars_button.button_pressed
	Globals.hardboiled_minions_flag = _hardboiled_minions_button.button_pressed
	Globals.no_public_medicine_flag = _no_public_medicine_button.button_pressed
	done.emit()

func _on_cancel():
	var bus_names = _volume_sliders.values()
	for i in _volume_sliders.size():
		Globals.set_volume(bus_names[i], _initial_volumes[i])
	_confirmed = false
	done.emit()

func _on_reset():
	var sliders = _volume_sliders.keys()
	var bus_names = _volume_sliders.values()
	for i in _volume_sliders.size():
		sliders[i].value = 100.0
		Globals.set_volume(bus_names[i], 1.0)
	_difficulty_slider.value = Globals.default_game_difficulty
	_drug_quality_button.button_pressed = false
	_plot_depth_button.button_pressed = false
	_corruption_button.button_pressed = false
	_inflation_button.button_pressed = false
	_vice_button.button_pressed = false
	_liars_button.button_pressed = false
	_hardboiled_minions_button.button_pressed = false
	_no_public_medicine_button.button_pressed = false

func is_confirmed() -> bool:
	return _confirmed

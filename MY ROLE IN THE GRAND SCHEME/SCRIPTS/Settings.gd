extends Node2D

signal done

@onready var _volume_sliders = {
	$Buttons_Sliders/Sliders/Master:		&"Master",
	$Buttons_Sliders/Sliders/Music:		&"MUSIC",
	$Buttons_Sliders/Sliders/FX:			&"FX",
	$Buttons_Sliders/Sliders/UI:			&"UI",
	$Buttons_Sliders/Sliders/Ambiance:	&"AMBIANCE",
	$Buttons_Sliders/Sliders/Video:		&"VIDEO"
}

const _default_volume = 0.5
var _initial_volumes: Array[float]

func _ready():
	var sliders = _volume_sliders.keys()
	var bus_names = _volume_sliders.values()
	for i in _volume_sliders.size():
		var volume = Globals.get_volume(bus_names[i])
		_initial_volumes.append(volume)
		sliders[i].value = volume * 100.0
		sliders[i].value_changed.connect(_on_volume_changed.bind(i))

	$Buttons_Sliders/Ok_Cancel_Reset_Buttons/Ok.pressed.connect(_on_ok)
	$Buttons_Sliders/Ok_Cancel_Reset_Buttons/Cancel.pressed.connect(_on_cancel)
	$Buttons_Sliders/Ok_Cancel_Reset_Buttons/Reset.pressed.connect(_on_reset)

func _on_volume_changed(value: float, index: int):
	var bus_name = _volume_sliders.values()[index]
	Globals.set_volume(bus_name, value / 100.0)

func _on_ok():
	done.emit()

func _on_cancel():
	var bus_names = _volume_sliders.values()
	for i in _volume_sliders.size():
		Globals.set_volume(bus_names[i], _initial_volumes[i])
	done.emit()

func _on_reset():
	var sliders = _volume_sliders.keys()
	var bus_names = _volume_sliders.values()
	for i in _volume_sliders.size():
		sliders[i].value = _default_volume * 100.0
		Globals.set_volume(bus_names[i], _default_volume)

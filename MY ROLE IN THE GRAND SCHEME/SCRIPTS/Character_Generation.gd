extends Node2D

signal confirm_pressed
signal cancel_pressed

func _ready():
	$Creation_Page.confirm_pressed.connect(_on_confirm_pressed)
	$Creation_Page.cancel_pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	confirm_pressed.emit()

func _on_cancel_pressed():
	cancel_pressed.emit()

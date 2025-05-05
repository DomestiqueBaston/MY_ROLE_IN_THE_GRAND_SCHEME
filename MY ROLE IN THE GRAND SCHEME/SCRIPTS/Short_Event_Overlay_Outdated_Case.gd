extends Control


@onready var animation_player = $"../../../Outdated_Case_Alarm"
@onready var alarm_animation = "Alarm"

var has_played = false


func _ready():
	if visible and not has_played:
		animation_player.play(alarm_animation)
		has_played = true

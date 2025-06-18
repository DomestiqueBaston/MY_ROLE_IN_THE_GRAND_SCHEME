extends TextureRect

@onready var collider = $"../Colliders/Interaction_Area/Interaction_Collider"

func _ready():
	visible = false

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		var local_rect = collider.shape.get_rect()
		var local_pos = collider.to_local(event.global_position)
		var inside = local_rect.has_point(local_pos)
		if visible != inside:
			visible = inside
			if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
				if inside:
					Globals.hover_sound.play()
				else:
					Globals.leave_sound.play()

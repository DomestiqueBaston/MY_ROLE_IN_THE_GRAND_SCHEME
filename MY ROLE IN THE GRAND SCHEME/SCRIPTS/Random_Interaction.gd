extends Sprite2D


func _ready():
	var random_index = randi_range(0, 2)

	$Dialogue.hide()
	$Combat.hide()
	$Investigation.hide()
	$"../Interaction/Dialogue".hide()
	$"../Interaction/Combat".hide()
	$"../Interaction/Investigation".hide()

	match random_index:
		0:
			$Dialogue.show()
			$"../Interaction/Dialogue".show()
		1:
			$Combat.show()
			$"../Interaction/Combat".show()
		2:
			$Investigation.show()
			$"../Interaction/Investigation".show()

extends Panel

@onready var hbox_container = $"../Text"

func _ready():
	var min_size = hbox_container.get_minimum_size()
	custom_minimum_size = Vector2(min_size.x + 13, min_size.y)

func _process(_delta):
	var min_size = hbox_container.get_minimum_size()
	custom_minimum_size = Vector2(min_size.x + 13, min_size.y)

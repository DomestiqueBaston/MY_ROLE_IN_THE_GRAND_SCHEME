extends TextureButton

@onready var node_to_toggle = $"../../Global_Shader_Overlay"
@onready var graphics_hover = $"../Graphics_Hover"

func _ready():
	self.connect("pressed", Callable(self, "_on_TextureButton_pressed"))
	self.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	self.connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	graphics_hover.hide()

func _on_TextureButton_pressed():
	if node_to_toggle.visible:
		node_to_toggle.hide()
	else:
		node_to_toggle.show()

func _on_mouse_entered():
	graphics_hover.show()

func _on_mouse_exited():
	graphics_hover.hide()

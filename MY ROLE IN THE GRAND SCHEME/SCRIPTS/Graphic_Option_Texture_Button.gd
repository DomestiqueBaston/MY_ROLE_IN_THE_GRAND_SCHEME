extends TextureButton

@onready var node_a_to_toggle = $"../../Global_Shader_Overlay/Grain"
@onready var node_b_to_toggle = $"../../Global_Shader_Overlay/Video"
@onready var graphics_hover = $"../Graphics_Hover"

func _ready():
	self.connect("pressed", Callable(self, "_on_TextureButton_pressed"))
	self.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	self.connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	graphics_hover.hide()

func _on_TextureButton_pressed():
	if node_a_to_toggle.visible:
		node_a_to_toggle.hide()
		$"../../Label".text = "                                                                                     [color=#ff8864]Video Shader[/color]: [color=#ff1c18][shake rate=10.0 level=5 connected=0]off[/shake][/color]"
	else:
		node_a_to_toggle.show()
		$"../../Label".text = "                                                                                     [color=#ff8864]Video Shader[/color]: [color=#ff1c18][shake rate=10.0 level=5 connected=0]on[/shake][/color]"
		
	if node_b_to_toggle.visible:
		node_b_to_toggle.hide()
		$"../../Label".text = "                                                                                     [color=#ff8864]Video Shader[/color]: [color=#ff1c18][shake rate=10.0 level=5 connected=0]off[/shake][/color]"
	else:
		node_b_to_toggle.show()
		$"../../Label".text = "                                                                                     [color=#ff8864]Video Shader[/color]: [color=#ff1c18][shake rate=10.0 level=5 connected=0]on[/shake][/color]"
		
	$"../../Switch".play()

func _on_mouse_entered():
	graphics_hover.show()
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	graphics_hover.hide()
	if $"../../Shared_Interface_Sounds/Hover".playing == true or $"../../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()


func _on_ok_pressed():
	$"../../Shared_Interface_Sounds/Cancel".play()
	await $"../../Shared_Interface_Sounds/Cancel".finished


func _on_ok_mouse_entered():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()


func _on_ok_mouse_exited():
	if $"../../Shared_Interface_Sounds/Hover".playing == true or $"../../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()

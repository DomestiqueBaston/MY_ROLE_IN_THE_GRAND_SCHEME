extends TextureRect

@export var target_collider_path: NodePath  # À assigner dans l'inspecteur
@onready var target_collider = get_node_or_null(target_collider_path)

var is_hovering = false

func _ready():
	if target_collider == null:
		push_error("target_collider is not assigné ou le chemin est incorrect.")
		print("Le chemin cible est : ", target_collider_path)
		set_process(false)
		return
	visible = false
	print("Collider trouvé :", target_collider)

func _process(_delta):
	if target_collider == null:
		return
		
		# Ignore les détections si le noeud parent est invisible
	if not get_node("../..").visible:
		return
	
	var mouse_position = get_viewport().get_mouse_position()
	var collider_position = target_collider.global_position

	# Vérification de la forme du collider avant de l'utiliser
	var shape = null
	if target_collider is CollisionShape2D:
		shape = target_collider.shape
	else:
		push_error("Le collider n'a pas de forme (shape).")
		return

	var rect = Rect2(collider_position - shape.extents, shape.extents * 2)

	if rect.has_point(mouse_position):
		if not is_hovering:
			_play_sound("Hover")
			is_hovering = true
			visible = true
	else:
		if is_hovering:
			_play_sound("Leave")
			is_hovering = false
			visible = false

func _play_sound(sound_type: String):
	if sound_type == "Hover":
		if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
			Globals.hover_sound.play()
	elif sound_type == "Leave":
		if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
			Globals.leave_sound.play()

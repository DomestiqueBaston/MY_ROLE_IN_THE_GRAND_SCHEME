extends Node

@onready var low: AudioStreamPlayer = $LOW
@onready var normal: AudioStreamPlayer = $NORMAL
@onready var high: AudioStreamPlayer = $HIGH

var current_track: int = 0
var tracks: Array = []

func _ready() -> void:
	# Ajouter les pistes dans un tableau
	tracks = [low, normal, high]

	# Initialiser les volumes des pistes
	low.volume_db = 0.0
	normal.volume_db = -80.0
	high.volume_db = -80.0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Left_Click"):
		next_track()

func next_track() -> void:
	# Passer à la piste suivante en ajustant les volumes
	current_track = (current_track + 1) % tracks.size()

	# Identifier les pistes actuelle et suivante
	var current = tracks[(current_track - 1 + tracks.size()) % tracks.size()]
	var next = tracks[current_track]

	# Créer un tween pour le crossfade ET en // pour qu'il se fassent simultanément.
	var tween = get_tree().create_tween().set_parallel(true)

	# Faire un crossfade
	tween.tween_property(next, "volume_db", 0.0, 3.0).set_trans(tween.TRANS_CIRC).set_ease(tween.EASE_OUT)
	tween.tween_property(current, "volume_db", -80.0, 3.0).set_trans(tween.TRANS_CIRC).set_ease(tween.EASE_IN)
	
	# Il aura fallu un paquet de temps pour me souvenir que les courbes en DB ne sont pas linéaires !

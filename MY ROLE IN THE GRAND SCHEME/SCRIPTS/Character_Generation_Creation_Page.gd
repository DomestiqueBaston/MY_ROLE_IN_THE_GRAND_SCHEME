extends Control


var total_points = 15  # Total de points à répartir
var phy = 3
var men = 3
var hea = 3
var remaining = total_points - (phy + men + hea)  # Initialiser remaining


func _on_any_button_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished

func _on_cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished

func _on_any_button_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()
	
func _on_any_button_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_h_slider_value_changed(value: float):
	var pitch = lerp(0.5, 0.504, value)
	$Sex_Choice.pitch_scale = pitch
	if not $Sex_Choice.playing:
		$Sex_Choice.play()

func _process(_delta):
	# Limiter remaining entre 0 et 11
	if remaining < 0:
		remaining = 0
	elif remaining > 11:
		remaining = 11
		
	# Affichage des valeurs à chaque frame
	$PHY.text = str(phy)
	$MEN.text = str(men)
	$HEA.text = str(hea)
	$Remaining_Points.text = str(remaining)

	if Input.is_action_just_released("Left_Click"):  # Si l'action Left_Click est relâchée
		$Sex_Choice.stop()


func _on_phy_moins_pressed():
	Globals.cancel_sound.play()
	if phy > 3:  # Vérifier si phy est supérieur à 3 avant de décrémenter
		phy -= 1
		remaining += 1
		update_remaining()  # Mettre à jour le nombre de points restants

func _on_phy_plus_pressed():
	Globals.valid_sound.play()
	if phy < 7 and remaining > 0:  # Vérifier si phy est inférieur à 7 avant d'incrémenter
		phy += 1
		remaining -= 1
		update_remaining()  # Mettre à jour le nombre de points restants

func _on_men_moins_pressed():
	Globals.cancel_sound.play()
	if men > 3:  # Vérifier si men est supérieur à 3 avant de décrémenter
		men -= 1
		remaining += 1
		update_remaining()  # Mettre à jour le nombre de points restants

func _on_men_plus_pressed():
	Globals.valid_sound.play()
	if men < 7 and remaining > 0:  # Vérifier si men est inférieur à 7 avant d'incrémenter
		men += 1
		remaining -= 1
		update_remaining()  # Mettre à jour le nombre de points restants

func _on_hea_moins_pressed():
	Globals.cancel_sound.play()
	if hea > 3:  # Vérifier si hea est supérieur à 3 avant de décrémenter
		hea -= 1
		remaining += 1
		update_remaining()  # Mettre à jour le nombre de points restants

func _on_hea_plus_pressed():
	Globals.valid_sound.play()
	if hea < 7 and remaining > 0:  # Vérifier si hea est inférieur à 7 avant d'incrémenter
		hea += 1
		remaining -= 1
		update_remaining()  # Mettre à jour le nombre de points restants

# Fonction pour mettre à jour remaining
func update_remaining():
	remaining = total_points - (phy + men + hea)
	if remaining < 0:
		remaining = 0
	elif remaining > 11:
		remaining = 11


func _on_randomize_pressed():
	Globals.valid_sound.play()
	# Répartition aléatoire des points entre 3 et 7 pour phy, men, et hea
	phy = randi_range(3, 7)
	men = randi_range(3, 7)
	hea = randi_range(3, 7)

	# Ajuster la somme des points pour qu'elle soit égale à total_points (15)
	var total_assigned = phy + men + hea
	#var diff = total_assigned - total_points

	# Si la somme dépasse total_points, on doit ajuster les valeurs
	while total_assigned != total_points:
		if total_assigned < total_points:
			# Ajouter des points là où c'est possible
			if phy < 7:
				phy += 1
			elif men < 7:
				men += 1
			elif hea < 7:
				hea += 1
		elif total_assigned > total_points:
			# Retirer des points là où c'est possible
			if phy > 3:
				phy -= 1
			elif men > 3:
				men -= 1
			elif hea > 3:
				hea -= 1
		total_assigned = phy + men + hea

	# Mettre à jour les points restants
	update_remaining()


func _on_reset_pressed():
	Globals.cancel_sound.play()
	phy = 3
	men = 3
	hea = 3
	total_points = 15
	update_remaining()

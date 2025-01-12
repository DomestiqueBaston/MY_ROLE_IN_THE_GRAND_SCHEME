FICHE PNJ

Structure type (en rouge les infos que le jeu ne donnera jamais au joueur):
ID : 						PNJxxx, etc.
Nom : 						Prénom + nom
Profession : 					(voir Professions) (bonus/malus inconnus du joueur)
Caractéristiques : 					PHY, MEN, HEA/HEAnom. et Wan = 0 à la création du PNJ
Jauge de HEA :					Vert/Orange/Rouge/Sans
Sbire :						Oui/Non
Rep (du joueur) : 					Rep_Joueur (auprès de ce PNJ)
Soupçon(s) de la victime : 				PNJ(s) (0 à 2)
Statut (Culpabilité réelle dans l’enquête) : 		Victime/Coupable/Complice/Suspect/Témoin/Aucun
Relations sociales (possiblement liées à l’enquête) :	En couple (0 à 1) : PNJ (homo 1/10 chance)
						Ami(s) (0 à 2) : PNJ
						Ennemi(s) (0 à 2) : PNJ
						Connaissance(s) (0 à 3) : PNJ
						Liaison (Amant/Maîtresse) (0 à 1) : PNJ (homo 1/10 chance)
						Dette/Influence (0 à 2) : PNJ
						Cause commune/Affinité idéologique (0 à 2) : PNJ
Emploi du temps :					Matin : (carte lieu)
						Après-midi : (carte lieu)
						Soirée : (carte lieu)
						Nuit : (carte lieu)
						W-E matin : (carte lieu)
						W-E après-midi : (carte lieu)
						W-E (soirée) : (carte lieu)
						W-E (nuit) : (carte lieu)
Lieu(x) alternatif(s) fréquenté(s) :			(1 à 2) : (carte Lieu)
Informations détenues sur d’autres PNJs : 		(1 à 2) : (Relations, Liens, Lieux)
Information(s) cachée(s) et incriminante(s) personelle(s) :	(1 à 2) : (Relations, Liens, Lieux)

Exemple de carte PNJ :
ID : 						PNJ001
Nom : 						Jean Mickey
Jauge de HEA :					Vert
Silhouette :					H
CARTE Abstraite

Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
 ID : 				ABSxxx, etc.
Nom : 				Nom de la carte
Type : 				Dialogue/Combat/Investigation/Abstraite
Description :			Très brève description de l’effet de la carte et de ses effets
Combinaisons possibles : 		Dialogue/Combat/Combat SPECIAL/Combat RUN AWAY/Investigation/Investigation SPECIAL/Investigation Break-In/Abstraite/Lieu/Objet/PNJ/Evidence
Combinaisons impossibles : 		Dialogue/Combat/Combat SPECIAL/Combat RUN AWAY/Investigation/Investigation SPECIAL/Investigation Break-In/Abstraite/Lieu/Objet/PNJ/Evidence
Bonus/Malus : 			…

Exemple :
ID : 				ABS001
Nom : 				Assurance
Type : 				Abstraite
Description :			Cette carte représente la confiance et la détermination du joueur. Agit sur MEN et Emo
Combinaisons possibles : 		Dialogue/Combat (all)/Investigation (all)/Lieu/Objet/PNJ/Evidence
Combinaisons impossibles : 		Abstraite
Bonus/Malus :			si Emo > 0 : +2MEN, -1Emo / si Emo < 0 : +2MEN, +1Emo / sinon :  +1MEN
Liste des cartes :
      Assurance :
	Description : Cette carte représente la confiance et la détermination du joueur. Elle améliore les capacités mentales en fonction de l'état émotionnel. 
          Emo > 0 : +2MEN, -1Emo
          Emo < 0 : +2MEN, +1Emo
          Sinon :  +1MEN

      Moral : 
	Description : Cette carte représente le moral et la motivation du joueur. Elle améliore les capacités physiques et mentales en fonction de l'état émotionnel. 
          Emo > 0 : +1PHY, +1MEN, +1Emo
          Emo < 0 : +1PHY, +1MEN, +2Emo
          Sinon : +1PHY, +1MEN

      Tempérament : 
	Description : Cette carte représente le tempérament et la résilience du joueur. Elle améliore les capacités physiques et mentales en fonction de l'état émotionnel. 
          Emo > 0 : +1PHY, -1MEN
          Emo < 0 : +1HEA, +1Emo
          Sinon : +1PHY, +1HEA, -1Emo

      Intérêt : 
	Description : Cette carte représente l'intérêt et la curiosité du joueur. Elle améliore les capacités mentales en fonction de l'état d'addiction. 
          Add > 0 : +1MEN, ±1Emo → Min/Max le plus proche
          Add < 0 : +2MEN, ±1Emo → Min/Max le plus proche
          Sinon : +1MEN

      Bravoure :
	Description : Cette carte représente la bravoure et le courage du joueur. Elle améliore les capacités physiques et mentales en fonction de l'état d'addiction. 
          Add > 0 : +1PHY, +1MEN, -1HEA
          Add < -1 : +1PHY, +1MEN, +2Add
          Sinon : +1PHY, +1MEN

	Résilience :
	Description : Cette carte représente la résilience et la capacité de récupération du joueur. Elle améliore les capacités de santé et mentales en fonction de l'état émotionnel. 
		Emo > 0 : +2HEA, -1Emo
		Emo < 0 : +1HEA, +1Emo
		Sinon : +1HEA, +1PHY

	Dopé :
	Description : Cette carte représente l'état de dopage du joueur. Elle améliore les capacités physiques et mentales en fonction de l'état d'addiction. 
		Si Add >0 : +1PHY, +1Add
		Si Add = 0 : +1PHY, +1MEN, +2Add
		Sinon : +2PHY, +2MEN, -2HEA, +3Add

	Clarté mentale : Cette carte représente la clarté d'esprit et la capacité du joueur à gérer ses émotions et ses addictions. Elle améliore les capacités mentales en fonction de l'état émotionnel et de l'addiction du joueur. 
	Description : 
		Emo ≠ 0 et Add ≠ 0 : +2MEN, ±1 Emo → Min/Max le plus proche et ±1Add → Min/Max le plus proche
		Emo ≠ 0 ou Add ≠ 0 : +1MEN, ±1 Emo → Min/Max le plus proche ou ±1Add → Min/Max le plus proche
		Sinon : +1MEN, +1HEA

	Équilibre Intérieur :
	Description : Cette carte représente l'équilibre intérieur et la stabilité émotionnelle du joueur. Elle aide à maintenir un état mental et émotionnel stable en ajustant l’émotion et l’addiction. 
          Emo = 0 et Add = 0 : +1HEA
Sinon :
Emo > 1 : -1Emo
Emo < -1 : /
Add > 1 : -1 Add
Add < -1 : /
CARTE Dialogue

Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			DIAxxx, DISxxx, DIRxxx, etc.
Nom : 			Nom de la carte
Type : 			Dialogue
Description : 		Très brève description de la carte
Combinaisons Possibles : 	Abstraite/Lieu/Objet/PNJ/Evidence
Combinaisons impossibles : 	Dialogue/Combat (all)/Investigation (all)
Bonus/Malus :		…

Exemple :
Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			PLA001
Nom : 			Argument logique
Type : 			Dialogue
Description : 		Une argumentation rationnelle et structurée pour convaincre
Combinaisons Possibles : 	Abstraite/Lieu/Objet/PNJ/Evidence
Combinaisons impossibles : 	Dialogue/Combat (all)/Investigation (all)
Bonus/Malus :		+1MEN
Liste des cartes Dialogue :
	- Argumentation logique : +1MEN
	- Avertissement prévenant : -1PHY, +1MEN
	- Conversation rassurante : +1Rep
	- Discussion informelle : +1MEN, -1 info aléatoirement choisie (si applicable)
	- Intimidation physique : +1PHY, -1Rep
	- Interrogatoire bruyant : +1PHY, -1Rep
	- Interrogatoire impitoyable : +2PHY, +1MEN, -2Rep
	- Interrogatoire subtil : +1MEN, +1 info (si réussite et applicable)
	- Interrogatoire violent : +2PHY, -2Rep
	- Menace voilée : +1 PHY, -1Rep
	- Mensonge convaincant : +1MEN, -1Rep si échec
	- Mise en garde : +1MEN, -1Rep
	- Offre de protection : +1 PHY, +1Rep
	- Pot-de-vin : +1 info (si réussite et applicable), -10Dø × Difficulté de l’enquête, +1Rep pour réussite/échec
	- Pot-de-vin généreux : +1MEN, -20Dø × Difficulté de l’enquête, +1 info (si réussite et applicable), +1Rep pour réussite/échec
	- Pression psychologique : +2MEN, -2Rep
	- Question indiscrète : +1MEN, +1 info (si réussite et applicable), -1Rep
	- Question piège : +1MEN, +1 info cachée (si réussite et applicable), -1Rep si échec 
CARTE Investigation

Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			INVxxx, INSxxx, INBxxx, etc.
Nom : 			Nom de la carte
Type : 			Investigation
Description : 		Très brève description de la carte
Combinaisons Possibles : 	Investigation SPECIAL/Investigation BREAK-IN/Abstraite
Combinaisons impossibles : 	Dialogue/Combat (all)/Investigation/Objet/PNJ/Lieu
Bonus/Malus :		…

Exemple :
Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			INV001
Nom : 			Analyse minutieuse
Type : 			Investigation
Description : 		Examine les détails avec une grande précision
Combinaisons Possibles : 	Investigation SPECIAL/Investigation BREAK-IN/Abstraite
Combinaisons impossibles : 	Dialogue/Combat (all)/Investigation/Objet/PNJ/Lieu
Bonus/Malus :		+1MEN, ±1Emo → 0
Liste des cartes Investigation :
	- Analyse minutieuse : +1 MEN, ±1 Emo → 0
	- Analyse succincte : -1MEN, -1 heure
	- Examen complet : +1MEN, +1PHY, ±2 Emo → Min/Max, +1 Objet, +2 heures
	- Examen méticuleux : +1PHY, -1Emo, +1 heure
	- Fouille approfondie : +1 PHY, +1 Objet, +2 heures
	- Fouille systématique : ±1 Emo → Min/Max
	- Inspection détaillée : +1MEN, ±1 Emo → Min/Max
	- Inspection rapide : -1PHY, -1MEN, ±1 Emo → 0 , -1 heure
	- Jeter un œil en passant : -1PHY, -1MEN, -1 Objet (minimum de 0), -2 heures (!)
	- Recherche méthodique : ±1 Emo → 0
	- Recherche rapide : -1PHY, -2 heures 

	SPECIAL (à jouer en combinaison avec une carte Investigation de la liste du dessus)
	- Avec du Luminol ! : +1MEN, +1Emo, +1 heure
	- Caméra endoscopique ! : -1PHY, +2MEN, +1 heure
	- Coup de bol ! : bonus de 1 au jet de dé, +2Emo
	- Démontage en règle ! : +1PHY, +2 heures
	- Ni vu, ni connu ! : Annule les malus d’Emo de l’autre carte de Combat, malus de 1 au jet de dé
	- Outils de crochetage ! : +2PHY, -1MEN, +1 heure
	- Outils improvisés ! : +1PHY, -2MEN, +1 heure
	- Prise d’empreintes ! : -1PHY, +1MEN, +1 heure
	- Utiliser un détecteur ! : -2PHY, +2MEN 

	BREAK-IN (avant Investigation)
	- Enfoncer la porte : +2PHY, -2MEN
	- Forcer la serrure : +1MEN, +1Emo
	- Grimper le long de la gouttière : +1PHY, +1Emo
	- Neutraliser la sécurité : +1MEN 
CARTE Combat

Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			COMxxx, COSxxx, CORxxx, etc.
Nom : 			Nom de la carte
Type : 			Combat
Description : 		Très brève description de la carte
Combinaisons Possibles : 	Combat SPECIAL/Combat RUN AWAY/Abstraite
Combinaisons impossibles : 	Dialogue/Investigation (all)/Combat/Objet/PNJ/Lieu
Bonus/Malus :		…

Exemple :
Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			COMxxx, COSxxx, CORxxx, etc.
Nom : 			Attaque ciblée
Type : 			Combat
Description : 		Effectue une attaque précise et concentrée
Combinaisons Possibles : 	Combat SPECIAL/Combat RUN AWAY/Abstraite
Combinaisons impossibles : 	Dialogue/Investigation (all)/Combat/Objet/PNJ/Lieu
Bonus/Malus :		+2PHY, -2Emo
Liste des cartes Combat :
	- Attaque ciblée : +2PHY, -2Emo
	- Charge : +1PHY, -1MEN, +1Emo
	- Combat de rues : ±1Emo → Min/Max
	- Contre-attaque : +1MEN, +1Emo
	- Couverture : -1PHY, -1MEN, ±1Emo → 0, -2 dégâts si le joueur est touché
	- Diversion : -1PHY, +2MEN, +1Emo
	- Esquive : -1MEN, -1Emo, -1 dégâts si le joueur est touché
	- Mouvements désordonnés : +2PHY, -1MEN, -2Emo
	- Parade : -1PHY, +1Emo, -1 dégâts si le joueur est touché
	- Provocation : +1MEN, ±1Emo → 0
	- Techniques martiales : +1PHY, +1MEN, -1Emo
	- Utiliser une arme : +3PHY, -1MEN, ±2Emo → Min/Max
	- Utiliser un objet : +1PHY 
	SPECIAL (à jouer en combinaison avec une carte Combat de la liste du dessus)
	- Adrénaline ! : bonus de 1 au jet de dé, ±1Add → Min/Max
	- Désarmer ! : le PNJ aura un malus de 1 à son jet de dé
	- Le tout pour le tout ! : bonus de 1 au jet de dé, les effets sur Emo sont augmentés de 1
	- Ne pas tuer ! : si le PNJ visé devait mourir, alors il sera à Hea = 1 ! Dialogue ensuite possible avec le PNJ (bonus de 1 au jet de dé de Dialogue)
	- Pas de bol ! : le PNJ aura un malus de 2 à son jet de dé et le joueur aura un malus de 1 à son jet de dé
	- Self-control ! : Annule les malus d’Emo de l’autre carte de Combat, malus de 1 au jet de dé 
	RUN AWAY (avant combat)
	- Fuir : +1PHY, +1MEN
CARTE Objet

Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			OBJxxx, etc.
Nom : 			Nom de la carte
Type : 			Objet
Description : 		Très brève description de la carte
Propriété :			1 PNJ
Evidence : 		Oui/Non
Combinaisons possibles : 	Dialogue/Abstraite
Combinaisons impossibles : 	Combat (all)/Investigation (all)/Lieu/Objet/PNJ/Evidence
Bonus/Malus :		/

Exemple :
ID : 			OBJ001
Nom : 			Agenda
Type : 			Objet
Description : 		Contient un emploi du temps passé d’une personne
Propriété :			PNJ001
Evidence : 		Oui
Combinaisons Possibles : 	Dialogue/Abstraite
Combinaisons impossibles : 	Combat (all)/Investigation (all)/Lieu/Objet/PNJ/Evidence
Bonus/Malus :		/

Liste des cartes Objet (Evidence possible) :
	Ces objets sont TOUJOURS liés à un PNJ (car ils sont « nominatifs »).
	- Agenda
	- Badge d’accès
	- Billet de transport
	- Carnet de notes personnel
	- Carnet de santé
	- Carte de visite
	- Clé
	- Clé USB
	- Contrat
	- Couteau
	- Empreintes digitales
	- Empreintes génétiques
	- Empreintes numériques
	- Facture
	- Ordinateur portable 
	- Photographie
	- Pistolet
	- Porte-feuilles
	- Réservation
	- Revolver
	- Téléphone portable
	- …


Liste des cartes Objet possiblement lié à un PNJ (Evidence impossible ou à moins d’empreintes ?) :
	- Agrafeuse
	- Baladeur
	- Briquet
	- Boîte vide
	- Boîte de pansements
	- Boîte de préservatifs
	- Cahier
	- Casquette
	- Casque de vélo
	- CD
	- Chargeur USB
	- Lampe de poche
	- Livre
	- Lunettes de soleil
	- Marqueur
	- Mètre ruban
	- Paquet de cigarettes
	- Pompe à vélo
	- Serviettes en papier
	- Stylo 
	- …
CARTE Lieu

Structure type (en rouge les infos que la carte n’affichera jamais au joueur):
ID : 			PLAxxx, etc.
Nom : 			Nom de la carte
Type : 			Lieu
Description : 		Très brève description de la carte
Propriété :			(0 à 2) PNJ
Evidence : 		Oui/Non
Combinaisons possibles : 	Dialogue/Abstraite
Combinaisons impossibles : 	Combat (all)/Investigation (all)/Lieu/Objet/PNJ/Evidence
Fréquentation :		(0 à 2) PNJ
Contenu trouvable :		(0 à 4) Carte Objet (« à la con »)
Contenu caché (Evidence) :	(0 à 2) Carte Objet
Ouverture : 		Matin / Après-midi / Soirée / Nuit (tous les jours) / Week-end (induit matin et après-midi uniquement) / H24 / N/A (lieu de vie par exemple, signifie « quelqu’un est à la maison »)
Bonus/Malus (sur place) :	…

Exemple :
ID : 			PLA001
Nom : 			Appartement
Type : 			Lieu
Description : 		C’est ici que vivent (PNJ) et (PNJ)
Propriété :			(PNJ)
Combinaisons Possibles : 	Dialogue/Abstraite
Combinaisons impossibles : 	Combat (all)/Investigation (all)/Lieu/Objet/PNJ/Evidence
Fréquentation :		PNJ003, etc.
Contenu trouvable :		OBJ001, OBJ002, etc.
Contenu caché (Evidence) :	OBJ003, etc.
Ouverture : 		N/A
Bonus/Malus (sur place) :	/

Liste des cartes Lieu (bonus/malus temporaires pour le joueur uniquement et seulement en étant sur place) :
	- Appartement : /
	- Atelier : -1PHY
	- Bibliothèque : +1MEN
	- Boutique/Magasin : -1MEN
	- Bureau : /
	- Cabinet : +1MEN
	- Café : -1MEN
	- Caserne : +1PHY, -1MEN (Combat impossible)
	- Cimetière : +1MEN
	- Cinéma : -1PHY
	- Discothèque : -1MEN
	- École : -1MEN
	- Galerie d’art : +1MEN
	- Garage : -1HEA
	- Hangar : +1PHY
	- Hôpital : -1PHY, +1HEA
	- Hôtel : /
	- Laboratoire : +1MEN
	- Lieu de culte : -1PHY, -1MEN
	- Marché aux puces : -1PHY
	- Musée : -1PHY
	- Parc : /
	- Piscine : -1PHY
	- Poste de Police : -1MEN (Combat impossible)
	- Restaurant : -1MEN
	- Salle de jeux : -1MEN
	- Salle de spectacle : -1PHY, +1MEN
	- Salle de sport : +1PHY, -1MEN
	- Stade : +1PHY
	- Station service : / 
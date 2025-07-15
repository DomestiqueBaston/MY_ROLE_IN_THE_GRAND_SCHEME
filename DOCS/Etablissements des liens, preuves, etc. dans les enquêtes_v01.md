– 1ère étape :
	- Choisir un Mobile de crime
	- /!\ Tous les mobiles ayant un lien « Intimacy » imposent un couple dans l’enquête. Les enquêtes d’adultère nécessitent un/une amant/amante en plus du couple.
	- /!\ Dans les enquêtes où la victime est décédée, la victime doit avoir au minimum 1 lien connu au départ de l’enquête avec un PNJ (coupable, complice, témoin, suspect…).
	- Infos données au joueur au départ d’une enquête :
		- En plus de Victim et Suspect, Witness, Crime Location s'ils sont connus, de la victime nommée au départ, on sait l'adresse (domicile), le job (Location), Schedule (hors hangout/hideout donc incomplet), relations sociales (ami/enemy/acquaintance/couple). Pour les autres que la victime, on sait l'adresse (domicile), le job (Location) et, uniquement s’ils sont liés/partagés avec la victime (vivante) : Schedule si travail au même endroit (hors hangout/hideout donc incomplet) et relations sociales (ami/enemy/acquaintance/couple).




– 2ème étape :
	- Définir les link, crime_location, known_crime_location, victims_professions, culprits_professions, victims, dead_victims, culprits, accomplices, suspects, witnesses, evidence_number, evidences.
	- /!\  Les liens incriminants (Vert foncé : Friend, Orange : Enemy, Gris : Debt/Influence, Rose : Intimacy, Bleu foncé : Ideology) sont à découvrir par le joueur pour valider une enquête avec succès CONTRAIREMENT À CE QU’ON PEUT LIRE DANS LES RÈGLES DES FOIS !	- /!\  « debt_influence », « intimacy » et « ideology » peuvent tout à fait se cumuler. Choix aléatoire et chacun a une chance sur deux d’être présent.
	- /!\  lorsqu’on a « friend » ou/et « enemy » ou/et acquaintance. Chacun a une chance sur deux d’être présent donc on peut n’en avoir aucun.
	- /!\  Lorsque « none » et d’autres choix sont possibles, si « none » est choisi, aucun autre lien ne sera ajouté (« none » est toujours seul).
	- /!\  Les liens incriminants (hors Victim, Culprit, Accomplice) sont répartis aléatoirement (en fonction de ce qui est tout de même autorisé) entre les coupables, victimes, complices.

	- Pour chaque personnage, on aura donc aussi défini son lieu de vie, son lieu de travail, ses Hangouts (1 à 2) et Hideout, son emploi du temps (travail, repos, week-end), links, properties, information_on_npc. Tout cela hors infos « secondaires » comme sexe, orientation sexuelle…
	- Chaque NPC a au moins 1 Acquaintance (en plus de l’éventuel conjoint).
	- Les NPCs (Friend) doivent partager un Hangout (+ appartement pour les couples).
	- Chaque lieu contient (en plus des éventuelles preuves) de 0 à 3 objets « à la con » (pas evidence et à 1 seul propriétaire) liés aux NPCs fréquentant le lieu !
	



- Pour définir quels liens incriminants dans une enquête, quels NPCs sont friend/enemy/connaissance/en_couple…
	- Il faut considérer 2 parties différentes (sans parler des « inutiles ») : les NPCs impliqués dans l’enquête et les NPCs indépendants de l’enquête (ceux qui n’ont pas d’implication directe dans l’enquête).

	Les NPCs indépendants de l’enquête :
	- Ils ont des liens totalement aléatoires ou même aucun. En fonction du lien, ils seront liés à n’importe qui de compatible  avec le lien choisi (exemple : on ne peut pas être l’ennemi de son ami):
		- couple : 50 % (dont 10 % homo)
		Pris dans un pool de 4 ennemis/amis/connaissances au total :
			- friend : de 0 à 2 (50 % liés au travail et 50 % liés au hangout).
			- enemy : de 0 à 2 (50 % liés au travail et 50 % liés au hangout).
			- acquaintance : de 0 à 2 (50 % liés au travail et 50 % liés au hangout).
		- affair (« lié » à intimacy) : 10 % de chance (on suit sexual_orientation). Le lien Affair est le même lien que Intimacy (rose) dans Main, il sert juste au jeu pour faire la différence entre couple officiel et non-officiel.
		- debt/influence et Ideology :
			- 1 PNJ aura 20 % de chance d’avoir 1 des 2 liens (Debt/Influence ou Ideology) avec n’importe qui (si l’enquête le nécessite : sauf la victime car déjà établi) et 10 % de chance d’avoir en plus l’autre lien avec n’importe qui (si l’enquête le nécessite : sauf la victime car déjà établi).

	Les NPCs impliqués dans l’enquête :
	- Les liens Culprit/Accomplice/Victim/Suspect/Witness sont établis au tout départ en générant ces NPCs après avoir décidé s’il y en a (comme Suspect, Witness et Accomplice) et combien dans l’enquête.
	- On établit ensuite les autres liens incriminants et on se réfère à « link » du Crime_Motive_Evidence.json en suivant les règles énoncées dans la 2ème étape à /!\ .
		- couple : 50 % (dont 10 % homo)
		Pris dans un pool de 4 ennemis/amis/connaissances au total :
			- friend : de 0 à 2 (50 % liés au travail et 50 % liés au hangout).
			- enemy : de 0 à 2 (50 % liés au travail et 50 % liés au hangout).
			- acquaintance : de 0 à 2 (50 % liés au travail et 50 % liés au hangout).
		- affair (« lié » à intimacy) : de 0 à 1 (homo. si Couple homo). Impératif en cas d'enquête avec lien Intimacy incriminant. Affair, c’est le même lien que Intimacy dans Main, il sert juste au jeu à faire la différence entre couple officiel et inofficiel.
		Concernant les Victimes dans les enquêtes nécessitant ces liens) :
		- debt/influence : X lien(s) où X est le nombre de coupables. Dans les enquêtes avec Debt/Influence incriminant, on a aussi ce lien ou Ideology entre coupables et complices.
		- ideology : X lien(s) où X est le nombre de coupables. Dans les enquêtes avec Ideology incriminant, on a aussi ce lien entre coupables et complices.
		Concernant les autres NPCs :
		- 1 PNJ aura 20 % de chance d’avoir 1 des 2 liens (Debt/Influence ou Ideology) avec n’importe qui (si l’enquête le nécessite : sauf la victime car déjà établi) et 10 % de chance d’avoir en plus l’autre lien avec n’importe qui (si l’enquête le nécessite : sauf la victime car déjà établi).


	- On peut aussi avoir d’autres liens mais ils ne seront pas incriminants. Globalement, c’est un peu comme si on passait en revue chaque lien et qu’on voit si le NPC a un tel lien ou pas sauf qu’en priorité, on procède d’abord pour les liens incriminants nécessaires pour l’enquête.



– 3ème étape (Pour définir à qui appartiennent les preuves et où elles se trouvent…) :
	- Selon  Crime_Motive_Evidence.json, on sait combien de preuves sont à répartir.
	- Répartir les evidences entre les coupables et complices avec au moins 1 preuve par coupable et 1 preuve par complice.
	- Le nombre d’evidences est TOUJOURS ≥ nombre de coupables+complices.
	- /!\ Dans certaines enquêtes nombre d’evidences minimum est toujours supérieur au nombre de coupables+complices.
	- /!\ Il est tout à fait possible d’avoir plus de preuves que de coupables+complices dans pas mal d’enquêtes (voir Crime_Motive_Evidence.json).
	Aléatoirement, on attribue les evidences comme suit :
	- 1 evidence appartenant à la victime doit se trouver dans le hideout d’un coupable ou d’un complice ou chez un coupable ou chez un complice ou sur le lieu de travail du coupable ou le lieu de travail du complice.
 et/ou (ou, c’est s’il n’y a qu’une preuve).
	- 1 evidence appartenant à 1 coupable ou 1 complice (ou à plusieurs) doit se trouver chez une victime ou sur le lieu du crime (s’il y a un lieu du crime).
	
	- Si 1 evidence a plusieurs propriétaires (coupable + victime ou complice + victime), elle se trouvera n’importe où et en priorité (2/3 chances) : sur le lieu du crime ou dans un lieu fréquenté par les propriétaires de la preuve (si un tel lieu existe et n’importe lequel s’il y en a plusieurs).
	- S’il reste des evidences, on continue la distribution avec ce qui reste.



– 4ème étape :
	- Rajout des NPCs « inutiles ». Voir tableau à Rajout des NPCs « inutiles » dans les règles (page 26/27)…



– NOTE :
	- /!\ Les sbires ne font pas partie du pool des NPCs. Ils sont générés en jeu au besoin.
	- On ne re-génère un nouveau sbire que s’il le dernier est mort, a disparu (prison)… Bref, lorsqu’il ne pourra plus revenir et il sera alors oublié jusqu’à la fin des temps !
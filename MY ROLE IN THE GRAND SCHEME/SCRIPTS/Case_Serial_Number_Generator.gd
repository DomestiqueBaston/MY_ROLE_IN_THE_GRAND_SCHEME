extends Label

func _ready():
	text = generate_case_name()


func generate_case_name() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var part1 = char(rng.randi_range(65, 90))  # Majuscule A-Z
	part1 += char(rng.randi_range(97, 122))    # Minuscule a-z

	var part2 = "%02d" % rng.randi_range(1, 99) # 01-99

	var part3 = char(rng.randi_range(65, 90))  # Majuscule
	part3 += char(rng.randi_range(97, 122))    # Minuscule
	part3 += str(rng.randi_range(1, 9))        # 1-9

	var part4 = str(rng.randi_range(1, 9))     # 1-9

	var case_name = "- Case %s#%s-%s.%s -" % [part1, part2, part3, part4]
	return case_name

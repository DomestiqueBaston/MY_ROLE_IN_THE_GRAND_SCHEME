extends Node

@export var player_name: String
@export var background: Dictionary
@export_range(0.0, 1.0) var sex: float
@export var physical: int
@export var mental: int
@export var max_health: int
@export var health: int
@export_range(-3, 3) var emotion: int
@export_range(-3, 3) var addiction: int
@export_range(0, 4) var wanted: int
@export var paranoia: int
@export var money: int
@export var debts: Array[int]
@export var drugs: int

func reset():
	player_name = ""
	background = {}
	sex = 0
	physical = 0
	mental = 0
	max_health = 0
	health = 0
	emotion = 0
	addiction = 0
	wanted = 0
	paranoia = 0
	money = 0
	debts.clear()
	drugs = 0

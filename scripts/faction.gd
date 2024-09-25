# Class for faction objects
class_name Faction
var faction_name: String
var starting_position: Vector2
var starting_position_id: int
var relations: Dictionary
var owned_hexes: Array = []

var CLAN_NAMES : Array = [
	"Leonard",
	"Mullen",
	"Dillon",
	"O'Friel",
	"Dunphy",
	"Hynes",
	"MacGee",
	"MacWard",
	"McKnight",
	"Nyland",
	"Dalton",
	"Joyce",
	"Owens",
	"Washburn",
	"Rearden",
	"Clancy",
	"Condon",
	"Kilroy",
	"Melville",
	"Moynihan",
	"Barry"
]

func _init(starting_position: Vector2):
	self.faction_name = CLAN_NAMES[randi() % CLAN_NAMES.size()]
	self.starting_position = starting_position
	self.relations = {}  # Diplomatic relations with other factions
	self.owned_hexes.append(starting_position)

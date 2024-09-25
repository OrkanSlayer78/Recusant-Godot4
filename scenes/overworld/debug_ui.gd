extends CanvasLayer

# Reference to the faction manager
@export var faction_manager_scene: PackedScene
var faction_manager: Node
var hex_map: Dictionary = {}
var grid_radius: float

# Button pressed to generate factions
func _on_faction_generation_button_pressed():
	faction_manager.call("generate_factions", hex_map, grid_radius)
	print("Faction generation triggered from debug UI")

# Button to reset the faction simulation
func _on_reset_simulation_button_pressed():
	faction_manager.call("simulate_factions", hex_map)
	
func set_hex_map(new_hex_map: Dictionary, new_radius: float):
	hex_map = new_hex_map
	grid_radius = new_radius
	


func _on_faction_generation_pressed() -> void:
	faction_manager.call("generate_factions", hex_map, grid_radius)
	print("Faction generation triggered from debug UI")


func _on_reset_simulation_pressed() -> void:
	faction_manager.call("simulate_factions", hex_map)

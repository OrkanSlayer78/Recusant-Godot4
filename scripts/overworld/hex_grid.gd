extends Node3D

# Size of the hex grid
@export var grid_radius: int = 40

# Size of each hex tile
@export var hex_radius: float = 0.51

@export var hex_tile: PackedScene
@export var player: PackedScene
@export var poi_scene: PackedScene

enum PointOfInterestType {
	NONE,
	CITY,
	CASTLE,
	MONASTERY,
	RUIN,
	DUNGEON,
	VILLAGE
}

var city_chance = .1


var elevation = FastNoiseLite.new()
var humidity = FastNoiseLite.new()
var avatar: Node3D

func _ready():
	# Initiate landscape seeds and scales
	elevation.seed = randi()
	humidity.seed = randi()
	elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation.frequency = 0.2
	humidity.noise_type = FastNoiseLite.TYPE_PERLIN
	humidity.frequency = .02


	generate_hex_grid()
	spawn_player()

func generate_hex_grid():
	var tile_id = 0
	for q in range(-grid_radius, grid_radius + 1):
		for r in range(max(-grid_radius, -q - grid_radius), min(grid_radius, -q + grid_radius) + 1):
			var e_value = elevation.get_noise_2d(q, r)
			var h_value = humidity.get_noise_2d(q, r)
			var biome
			# Instantiate the hex tile
			var hex = hex_tile.instantiate()
			hex.name = "HexTile - " + str(tile_id)
			hex.set_meta("id", tile_id)
			hex.call_deferred("initialize_hex", q, r)
			var hex_input_script = hex.get_node("StaticBody3D")  # Make sure this matches your node structure
			if hex_input_script:
				hex_input_script.connect("hex_selected", Callable(self, "_on_hex_selected"))
			else:
				print("Error: Could not find StaticBody3D in hex tile")

			# Call the biome generation method if available
			if hex and hex.has_method("generate_biome"):
				biome = hex.call_deferred("generate_biome",e_value, h_value)
				hex.set_meta("biome", biome)
				hex.global_transform.origin.y = e_value * 0.4

			# Add the hex to the scene tree first
			

			
			hex.call_deferred("set_global_position", hex_to_world_position(q, r, hex.transform.origin))
			
			
			add_child(hex)
			var roll = randf()
			if roll < city_chance:
				var poi_type = PointOfInterestType.CITY
				place_poi_on_tile(hex, poi_type)
			
			#hex.call_deferred("adjust_height", biome, e_value)
			
			tile_id += 1

# Convert hex coordinates to world position
func hex_to_world_position(q: int, r: int, current_position: Vector3) -> Vector3:
	var x = hex_radius * 3.0 / 2.0 * q
	var z = hex_radius * sqrt(3) * (r + q / 2.0)
	return Vector3(x, current_position.y, z)

func spawn_player():
	avatar = player.instantiate()
	add_child(avatar)
	avatar.global_transform.origin = Vector3(0, 0, 0)
	
	


func place_poi_on_tile(hex: Node3D, poi_type: PointOfInterestType):
	var poi = poi_scene.instantiate()
	poi.call("initialize_poi", poi_type)
	hex.add_child(poi)

func _on_hex_selected(q: int, r: int):
	print("Tile selected at q = ", q, "r = ", r)
	if avatar:
		avatar.call("move_to_hex", q, r)

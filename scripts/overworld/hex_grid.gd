extends Node3D

# Size of the hex grid
var grid_radius: int = 25

# Size of each hex tile
var hex_radius: float = 0.51

@export var hex_tile: PackedScene
@export var player: PackedScene

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

			# Instantiate the hex tile
			var hex = hex_tile.instantiate()
			hex.name = "HexTile - " + str(tile_id)
			hex.set_meta("id", tile_id)

			# Call the biome generation method if available
			if hex and hex.has_method("generate_biome"):
				var biome = hex.call_deferred("generate_biome",e_value, h_value)
				hex.set_meta("biome", biome)

			# Add the hex to the scene tree first
			add_child(hex)

			# After adding to the tree, safely adjust the position using `call_deferred`
			hex.call_deferred("set_global_position", hex_to_world_position(q, r))
			
			tile_id += 1

# Convert hex coordinates to world position
func hex_to_world_position(q: int, r: int) -> Vector3:
	var x = hex_radius * 3.0 / 2.0 * q
	var z = hex_radius * sqrt(3) * (r + q / 2.0)
	return Vector3(x, 0, z)

func spawn_player():
	avatar = player.instantiate()
	add_child(avatar)
	avatar.global_transform.origin = Vector3(0, 0, 0)

extends Node3D

# Size of the hex grid
@export var grid_radius: int = 10

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
var city_positions = []


var elevation = FastNoiseLite.new()
var humidity = FastNoiseLite.new()
var avatar: Node3D
var hex_map = {}
var global_astar = AStar3D.new()

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
	call_deferred("generate_roads")

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
			add_child(hex)
			hex.call_deferred("initialize_hex", q, r)
			
			var hex_input_script = hex.get_node("StaticBody3D")  # Make sure this matches your node structure
			if hex_input_script:
				hex_input_script.connect("hex_selected", Callable(self, "_on_hex_selected"))
			else:
				print("Error: Could not find StaticBody3D in hex tile")

			# Call the biome generation method if available
			if hex and hex.has_method("generate_biome"):
				biome = hex.call_deferred("generate_biome",e_value, h_value)
				hex.call_deferred("set_meta", "biome", biome)
				hex.global_transform.origin.y = e_value * 0.4
			hex.call_deferred("set_global_position", hex_to_world_position(q, r, hex.transform.origin))
			var roll = randf()
			if roll < city_chance:
				var poi_type = PointOfInterestType.CITY
				call_deferred("place_poi_on_tile",hex, poi_type)
			#hex.call_deferred("adjust_height", biome, e_value)
			
			call_deferred("add_to_hex_map", hex, q, r, tile_id, e_value, h_value)
			#create hex map to do pathfinding and other calculations
	
			
			tile_id += 1
	
# Convert hex coordinates to world position
func hex_to_world_position(q: int, r: int, current_position: Vector3) -> Vector3:
	var x = hex_radius * 3.0 / 2.0 * q
	var z = hex_radius * sqrt(3) * (r + q / 2.0)
	return Vector3(x, current_position.y, z)

func add_to_hex_map(hex: Node3D, q: int, r: int, tile_id: int, e_value, h_value):
	var position = hex.global_transform.origin

	# Add the hex to global AStar
	global_astar.add_point(tile_id, position)
	#print("Registered hex:", tile_id, " at position ", position)
	# Get the neighbors and connect to the AStar graph
	for neighbor in get_hex_neighbors(q, r):
		if hex_map.has(neighbor):  # Ensure the neighbor exists in hex_map
			var neighbor_id = hex_map[neighbor]["hex_id"]
			var neighbor_position = hex_map[neighbor]["position"]
			var elevation_diff = abs(e_value - hex_map[neighbor]["elevation"])
			var cost = 1.0 + elevation_diff * 50.0  # Adjust cost based on elevation difference

			# Connect the current hex to the neighbor in AStar
			global_astar.connect_points(tile_id, neighbor_id, cost)

# Add this hex to the hex_map
	hex_map[Vector2(q, r)] = {
		"position": hex.global_transform.origin,
		"elevation": e_value,
		"humidity": h_value,
		"neighbors": get_hex_neighbors(q, r),
		"hex_id": tile_id
		}

	# Debug: Print to ensure correct global position
	#print("Added hex to hex_map:", hex.global_transform.origin)
		
func spawn_player():
	avatar = player.instantiate()
	add_child(avatar)
	avatar.global_transform.origin = Vector3(0, 0, 0)
	
	
func place_poi_on_tile(hex: Node3D, poi_type: PointOfInterestType):
	var city_position = hex.global_transform.origin
	# Check distance to other cities
	for existing_city_position in city_positions:
		if existing_city_position.distance_to(city_position) < randi_range(.3, 4) :  # Threshold distance in world units
			#print("Skipping city placement due to proximity to another city.")
			return  # Skip placing this city
	
	# If city is far enough from other cities, place it
	var poi = poi_scene.instantiate()
	poi.call("initialize_poi", poi_type)
	hex.add_child(poi)
	#print(city_position)
	city_positions.append(city_position)  # Track placed city position
	#print("City placed at:", city_position)
	#var poi = poi_scene.instantiate()
	#poi.call("initialize_poi", poi_type)
	#hex.add_child(poi)

func _on_hex_selected(q: int, r: int):
	#print("Tile selected at q = ", q, "r = ", r)
	#if avatar:
	#	avatar.call("move_to_hex", q, r)
	print("Tile selected at q =", q, "r =", r)

	# Find the path from the player's current position to the selected hex
	var player_position = avatar.global_transform.origin
	var target_position = hex_to_world_position(q, r, Vector3(0, 0, 0))  # Convert hex to world position

	var path = find_path_with_elevation_cost(player_position, target_position)
	avatar.call("move_along_path", path)  # Call the player's move_along_path function
		

func generate_roads():
	for city_position in city_positions:
		var nearest_city = find_nearest_city(city_position)
		if nearest_city != null:
			#print("Found cities to link - ", city_position, " to ", nearest_city)
			#reate_road(city_position, nearest_city)
			var path = find_path_with_elevation_cost(city_position, nearest_city)
			var positions = get_path_positions(path)
			print("Creating roads with positions - " , positions)
			create_curved_road(positions)
			
			create_debug_road(city_position, nearest_city)

func get_path_positions(path: Array) -> Array:
	var positions = []
	for point in path:
		# Iterate through hex_map and find the hex ID that corresponds to this position (Vector3)
		for hex_id in hex_map.keys():
			var hex_position = hex_map[hex_id]["position"]
			if hex_position.distance_to(point) < 0.1:  # Check if the position matches the point
				positions.append(hex_position)
				break  # Stop searching once we've found the matching hex
	return positions
	

func create_curved_road(path: Array):
	var width = 0.1
	if path.size() < 2:
		print("Path too short to create a road.")
		return

	# Create SurfaceTool and start drawing a line
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	# Add all points from the path to the surface tool
	#for point in path:
	#	print("Adding point to path")
	#	surface_tool.add_vertex(point)
	
	for i in range(path.size() - 1):
		var point_a = path[i] + Vector3(0,.07,0)
		var point_b = path[i + 1] +Vector3(0,.07,0)
		
		# Calculate the direction between the points
		var direction = (point_b - point_a).normalized()
		
		# Calculate perpendicular offset for road width
		var perpendicular = Vector3(-direction.z, 0, direction.x) * width
		
		# Add two vertices for each point to create the width of the road
		surface_tool.add_vertex(point_a + perpendicular)  # Left side of the road
		surface_tool.add_vertex(point_a - perpendicular)  # Right side of the road
		
		surface_tool.add_vertex(point_b + perpendicular)  # Left side of the road
		surface_tool.add_vertex(point_b - perpendicular)  # Right side of the road


	# Commit the mesh to ImmediateMesh
	var road_mesh = surface_tool.commit()
	print("Surface count:", road_mesh.get_surface_count())

	# Ensure the mesh has at least one surface before applying material
	if road_mesh.get_surface_count() == 0:
		print("Error: No surfaces created for the road mesh.")
		return

	# Create a MeshInstance3D to hold the road mesh
	print("creating new mesh")
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = road_mesh

	# Apply a simple material for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5647, 0.52549, 0.4588235)  # Red color for visibility
	mesh_instance.set_surface_override_material(0, material)

	# Add the MeshInstance to the scene
	print("Adding road to scene")
	add_child(mesh_instance)

	# Debug: Print to confirm road creation
	print("Created curved road with path:", path)
	
	
func find_nearest_city(current_city: Vector3) -> Vector3:
	var nearest_city = null
	var min_distance = INF
	for other_city in city_positions:
		if other_city != current_city:
			var distance = current_city.distance_to(other_city)
			if distance < min_distance:
				min_distance = distance
				nearest_city = other_city
	return nearest_city
	
func find_path_with_elevation_cost(start_hex: Vector3, end_hex: Vector3) -> Array:
	# Find the closest hex IDs for the start and end positions (in 3D)
	var start_id = find_closest_hex_id(start_hex)
	var end_id = find_closest_hex_id(end_hex)

	# Ensure that the start and end hexes are valid
	if start_id == null or end_id == null:
		print("Error: Start or End hex ID not found.")
		return []

	# Find the path using the pre-registered global AStar3D
	var path = global_astar.get_point_path(start_id, end_id)

	# DEBUG: Print the path to inspect
	print("AStar3D Path:", path)

	return path
	
func find_closest_hex_id(position: Vector3) -> int:
	var closest_id = null
	var min_distance = INF
	for hex_id in hex_map.keys():
		var hex_position = hex_map[hex_id]["position"]
		var distance = position.distance_to(hex_position)
		if distance < min_distance:
			min_distance = distance
			closest_id = hex_map[hex_id]["hex_id"]
	return closest_id
	
	
func get_hex_neighbors(q: int, r: int) -> Array:
	var neighbors = []
	
	# Define the relative offsets for the 6 neighbors in axial coordinates
	var neighbor_offsets = [
		Vector2(1, 0),   # North-East
		Vector2(1, -1),  # East
		Vector2(0, -1),  # South-East
		Vector2(-1, 0),  # South-West
		Vector2(-1, 1),  # West
		Vector2(0, 1)    # North-West
		]
	
	# Calculate neighbors' positions and add them to the list
	for offset in neighbor_offsets:
		var neighbor_q = q + offset.x
		var neighbor_r = r + offset.y
		
		if abs(neighbor_q) <= grid_radius and abs(neighbor_r) <= grid_radius:
			var neighbor_id = Vector2(neighbor_q, neighbor_r)
			neighbors.append(neighbor_id)
	
	return neighbors
	
func create_debug_road(start_pos: Vector3, end_pos: Vector3):
	# Create SurfaceTool and start drawing a line
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	# Add the start and end vertices
	surface_tool.add_vertex(start_pos)
	surface_tool.add_vertex(end_pos)
	
	# Commit the mesh to ImmediateMesh
	var road_mesh = surface_tool.commit()
	
	# Create a MeshInstance3D to hold the road mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = road_mesh
	
	# Apply a simple material to the mesh for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.1, 0.1)  # Red color for visibility
	mesh_instance.set_surface_override_material(0, material)
	
	# Add the MeshInstance to the scene
	add_child(mesh_instance)
	
	# Debug: Print start and end positions to verify correctness
	print("Debug road created from", start_pos, "to", end_pos)

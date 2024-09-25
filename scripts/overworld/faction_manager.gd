extends Node3D

const Faction = preload("res://scripts/faction.gd")

var factions = []  # Store generated factions
var faction_colors = {}
@export var faction_count: int = 5  # Number of factions to generate

# Generate random factions and assign starting hexes
func generate_factions(hex_map: Dictionary, grid_radius: int):
	factions.clear()  # Clear previous faction data
	faction_colors.clear()
	for i in range(faction_count):
		var starting_hex = get_random_hex_position(grid_radius)
		var faction = Faction.new(starting_hex)
		
		var faction_color = Color(randf(), randf(), randf())
		faction_colors[faction.faction_name] = faction_color
		
		# Set relations with other factions
		for other_faction in factions:
			var relation = randf_range(-1, 1)  # -1 = hostile, 0 = neutral, 1 = friendly
			faction.relations[other_faction.faction_name] = relation
			other_faction.relations[faction.faction_name] = relation

		factions.append(faction)
		print("Generated faction:", faction.faction_name, " starting at:", starting_hex)

	return factions
	
func set_faction_init_id(faction: String, starting_position_id: int):
	for entry in factions:
		if entry.name == faction:
			entry.starting_position_id = starting_position_id

# Helper function to get a random hex position for faction starting location
func get_random_hex_position(grid_radius: int) -> Vector2:
	var random_q = randi_range(-grid_radius, grid_radius)
	var random_r = randi_range(max(-grid_radius, -random_q - grid_radius), min(grid_radius, -random_q + grid_radius))
	return Vector2(random_q, random_r)
	
#place flags on conquered hexes
func place_faction_flag_on_hex(faction_name: String, hex_position: Vector3):
	var flag = preload("res://scenes/overworld/flag.tscn").instantiate()

	# Add flag to the scene first before setting its transform
	add_child(flag)

	# Use call_deferred to ensure it's in the scene tree before setting the transform
	flag.call_deferred("set_global_position", hex_position + Vector3(0, 0.1, 0))

	# Get the MeshInstance3D node from the flag (adjust the path if necessary)
	print("Flag children: ", flag.get_children())
	var mesh_instance = flag.get_node("MeshInstance3D")
	
	if mesh_instance and mesh_instance.mesh:
		var surface_count = mesh_instance.mesh.get_surface_count()

		if surface_count > 0:
			# Set the flag's material color based on the faction
			var material = StandardMaterial3D.new()
			material.albedo_color = faction_colors[faction_name]

			# Apply the material to the first surface (index 0)
			mesh_instance.set_surface_override_material(0, material)
		else:
			print("Error: Mesh has no surfaces!")
	else:
		print("Error: MeshInstance3D or Mesh is missing!")

	print("Placed flag for faction", faction_name, "at", hex_position)
	

# Simulate faction expansion or diplomacy
func simulate_factions(hex_map: Dictionary, iterations: int):
	while iterations > 0:
		for faction in factions:
			var new_owned_hexes = []  # To store newly conquered hexes
			
			# Expand from all hexes the faction owns
			for owned_hex in faction.owned_hexes:
				var neighbors = hex_map[owned_hex]["neighbors"]
				
				for neighbor in neighbors:
					if hex_map.has(neighbor):
						var hex_owner = hex_map[neighbor]["faction"]
						
						if hex_owner == null:
							# Expand into unowned territory with success/failure chance
							if randf() < 0.7:  # 70% chance of successful expansion
								hex_map[neighbor]["faction"] = faction.faction_name
								print(faction.faction_name, "expanded to", neighbor)
								
								# Place a flag to mark the conquered territory
								place_faction_flag_on_hex(faction.faction_name, hex_map[neighbor]["position"])
								
								new_owned_hexes.append(neighbor)
							else:
								print(faction.faction_name, "failed to conquer", neighbor)
						
						elif faction.relations.has(hex_owner) and hex_owner != faction.faction_name:
							if faction.relations[hex_owner] < 0 and randf() < 0.5:  # 50% chance of conquest in hostile relations
								print(faction.faction_name, "conquered territory from", hex_owner)
								hex_map[neighbor]["faction"] = faction.faction_name
								
								# Place a flag for conquered territory
								place_faction_flag_on_hex(faction.faction_name, hex_map[neighbor]["position"])
								
								new_owned_hexes.append(neighbor)
							else:
								print(faction.faction_name, "failed to conquer", hex_owner)
			
			# Add newly conquered hexes to the faction's territory
			faction.owned_hexes.append_array(new_owned_hexes)
		
		iterations -= 1

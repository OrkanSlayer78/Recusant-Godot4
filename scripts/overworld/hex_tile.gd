extends Node3D

# Define biome types
enum Biome {
	PLAINS,
	HILLS,
	MOUNTAINS,
	SWAMP,
	FIELDS
}

#setup clickability
signal hex_selected(q,r)

var q: int
var r: int
var hex_biome: Biome

# Cache the mesh instance and material reference
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var base_material: StandardMaterial3D

func _ready():
	# Get the StaticBody3d node
	static_body = get_node("StaticBody3D")

	# Get the MeshInstance3D node
	mesh_instance = get_node("MeshInstance3D")  # Adjust path if necessary
	if mesh_instance and mesh_instance.mesh:
		# Get the current material
		var material = mesh_instance.get_active_material(0)
		if material != null:
			# Deep duplicate the material for per-tile customization
			base_material = material.duplicate(true)
		else:
			# Create a new material if one doesn't exist
			base_material = StandardMaterial3D.new()
		# Assign the unique material to this instance (not the shared mesh)
		mesh_instance.set_material_override(base_material)
	else:
		print("MeshInstance3D or its mesh is missing!")

# Generate the biome based on elevation and humidity
func generate_biome(elevation: float, humidity: float) -> Biome:
	if mesh_instance == null or base_material == null:
		print("MeshInstance or Material not initialized!")
		return Biome.PLAINS  # Return a default value to prevent errors
	
	var biome: Biome = get_biome_from_elevation(elevation)
	adjust_height(biome, elevation)
	adjust_color(elevation, humidity)
	hex_biome = biome
	return biome

# Determine the biome based on elevation
func get_biome_from_elevation(elevation: float) -> Biome:
	if elevation < -0.2:
		return Biome.SWAMP
	elif elevation < 0.3:
		return Biome.PLAINS
	elif elevation < 0.4:
		return Biome.FIELDS
	elif elevation < 0.6:
		return Biome.HILLS
	else:
		return Biome.MOUNTAINS

# Adjust the height based on the biome
func adjust_height(biome: Biome, elevation: float) -> float:
	var scale_adjustment: float = 1.0
	var height_adjustment: float = 0

	# Adjust the height and scale based on the biome
	if biome == Biome.SWAMP:
		height_adjustment = elevation
		scale_adjustment = 1
	elif biome == Biome.PLAINS:
		height_adjustment = elevation * 3
		scale_adjustment = 5 
	elif biome == Biome.FIELDS:
		height_adjustment = elevation * 5
		scale_adjustment = 5
	elif biome == Biome.HILLS:
		height_adjustment = elevation * 10
		scale_adjustment = 5
	elif biome == Biome.MOUNTAINS:
		height_adjustment = elevation * 20
		scale_adjustment = 10

	# Modify the height (Y position) of the mesh
	#print(height_adjustment)
	return height_adjustment


func initialize_hex(q_val: int, r_val: int):
	if static_body:
		static_body.call("initialize_hex", q_val, r_val)

# Adjust the color based on elevation and humidity
func adjust_color(elevation: float, humidity: float) -> void:
	if base_material == null:
		print("Lost my material when trying to color")
		return

	# Define base color depending on the elevation
	var base_color: Color
	if elevation < -0.2:
		base_color = Color(140/256.0, 102/256.0, 81/256.0) #swamp 
	elif elevation < 0.3:
		base_color = Color(81/256.0, 89/256.0, 26/256.0)  # plains
	elif elevation < 0.4:
		base_color = Color(136/256.0, 140/256.0, 39/256.0)  # fields
	elif elevation < 0.6:
		base_color = Color(161/256.0, 165/256.0, 31/256.0)  # hill
	else:
		base_color = Color(197/256.0, 205/256.0, 216/256.0)  # mountains

	# Adjust the color's blueness based on humidity
	var blue_adjustment = clamp(humidity, 0.0, 0.75)
	var final_color = base_color.lerp(Color(-0.1, 0.8, .5), blue_adjustment)

	# Apply the final color to the material
	base_material.albedo_color = final_color

	# No need to set the material again since it's already assigned to this instance

extends Node

enum Biome {
	PLAINS,
	HILLS,
	MOUNTAINS,
	SWAMP,
	FIELDS
}


#mountain displacement
func displace_mountain_tile(tile: MeshInstance3D):
	var mesh = tile.mesh
	if mesh == null:
		print("Mesh is missing")
		return
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	#select geometry
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	#displace top vertices
	for i in range(vertices.size()):
		var vertex = vertices[i]
		if vertex.y > 0.5:
			vertex.y += randf_range(0.2, 0.6)
		surface_tool.add_vertex(vertex)
		
	surface_tool.commit()
	
#forest generation logic
func generate_forest_foliage(tile: Node3D, elevation: float, humidity: float, hex_radius: float):
	match tile.hex_biome:
		Biome.MOUNTAINS:
			if elevation > 0.1:
				displace_mountain_tile(tile.get_node("MeshInstance3D"))
				generate_conifer_forest(tile, hex_radius)
			else:
				generate_broadleaf_forest(tile, hex_radius)
		Biome.PLAINS:
			print("Plains are lame")
		Biome.HILLS:
			if humidity > 0.4:
				generate_broadleaf_forest(tile, hex_radius)
			else:
				generate_misc_foliage(tile, hex_radius)
		Biome.SWAMP:
			generate_misc_foliage(tile, hex_radius)
		Biome.FIELDS:
			if humidity > .2:
				generate_broadleaf_forest(tile, hex_radius)
		
func generate_conifer_forest(tile: Node3D, hex_radius: float):
	var conifer_tree_scene = preload("res://scenes/overworld/foliage/conifer_tree.tscn")
	var tree_count = randi_range(2, 8)
	for i in range(tree_count):
		var tree = conifer_tree_scene.instantiate()
		var x_offset = randf_range(-hex_radius, hex_radius)
		var z_offset = randf_range(-hex_radius, hex_radius)
		tile.add_child(tree)
		tree.rotation_degrees.y = randf_range(0,360)
		tree.global_transform.origin = tile.global_transform.origin + Vector3(x_offset, 0, z_offset)
		
		
func generate_broadleaf_forest(tile: Node3D, hex_radius: float):
	var conifer_tree_scene = preload("res://scenes/overworld/foliage/broadleaf.tscn")
	var tree_count = randi_range(1, 5)
	for i in range(tree_count):
		var tree = conifer_tree_scene.instantiate()
		var x_offset = randf_range(-hex_radius, hex_radius)
		var z_offset = randf_range(-hex_radius, hex_radius)
		tile.add_child(tree)
		tree.rotation_degrees.y = randf_range(0,360)
		tree.global_transform.origin = tile.global_transform.origin + Vector3(x_offset, 0, z_offset)
		
		
func generate_misc_foliage(tile: Node3D, hex_radius: float):
	var foliage_scenes = [
		preload("res://scenes/overworld/foliage/misc_foliage.tscn")
		#add more different plant scenes here to diversify the landscape
	]
	var foliage_count = randi_range(2, 5)
	for i in range(foliage_count):
		var foliage = foliage_scenes[randi() % foliage_scenes.size()].instantiate()
		
		var x_offset = randf_range(-hex_radius, hex_radius)
		var z_offset = randf_range(-hex_radius, hex_radius)
		tile.add_child(foliage)
		foliage.rotation_degrees.y = randf_range(0,360)
		foliage.global_transform.origin = tile.global_transform.origin + Vector3(x_offset, 0, z_offset)
		
		
		
	

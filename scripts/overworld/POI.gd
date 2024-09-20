extends Node3D

enum PointOfInterestType {
	NONE,
	CITY,
	CASTLE,
	MONASTERY,
	RUIN,
	DUNGEON,
	VILLAGE
}

@export var poi_type: PointOfInterestType = PointOfInterestType.NONE

# Called when the POI is first created
func initialize_poi(poi_type: PointOfInterestType):
	self.poi_type = poi_type
	update_visuals()

# Update the visual representation based on the POI type
func update_visuals():
	match poi_type:
		PointOfInterestType.CITY:
			$MeshInstance3D.mesh = load("res://res/obj/POI/A_small_midevil_villa_0919133053_refine.obj")
		PointOfInterestType.CASTLE:
			$MeshInstance3D.mesh = load("res://res/obj/POI/A_small_midevil_villa_0919133151_preview.obj/")
		PointOfInterestType.MONASTERY:
			$MeshInstance3D.mesh = load("res://res/obj/POI/a_small_midevil_irish_0919133252_preview.obj")
		PointOfInterestType.RUIN:
			$MeshInstance3D.mesh = load("res://res/obj/POI/A_ruined_entry_to_an__0919133231_preview.obj")
		PointOfInterestType.DUNGEON:
			$MeshInstance3D.mesh = load("res://res/obj/POI/a_tree_model_for_an_i_0919133357_preview.obj")
		PointOfInterestType.VILLAGE:
			$MeshInstance3D.mesh = load("res://res/obj/POI/A_small_midevil_villa_0919133208_preview.obj")
		PointOfInterestType.NONE:
			queue_free()  # No POI, just remove this node

# Additional functionality for quest generation, NPC placement, faction interaction can go here

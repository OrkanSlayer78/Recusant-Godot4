extends CanvasLayer

# Reference to the player and NPC in the scene
@export var player: Node
@export var npc: Node

# Function for interacting with the NPC
func _on_interact_with_npc_pressed():
	if player.global_transform.origin.distance_to(npc.global_transform.origin) < 200.0:
		print("Interacting with NPC...")
		# Add dialogue or other interaction logic here
	else:
		print("You are too far away from the NPC!")

# Function to return to the overworld
func _on_return_to_overworld_pressed():
	print("Returning to the overworld...")
	# Change to the overworld scene
	get_tree().change_scene_to_file("res://scenes/overworld/Hex-Grid.tscn")

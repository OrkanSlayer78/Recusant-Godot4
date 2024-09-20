extends StaticBody3D

func _ready():
	print("StaticBody3D is ready to detect clicks")

# Updated function signature for input events in Godot 4.x
func _input_event(camera: Camera3D, event: InputEvent, click_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("StaticBody3D clicked at position: ", click_position)

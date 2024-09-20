extends StaticBody3D

signal hex_selected(q, r)

var q: int
var r: int

# Initialize hex coordinates
func initialize_hex(q_val: int, r_val: int):
	q = q_val
	r = r_val

# Detect clicks on the hex tile
func _input_event(camera: Camera3D, event: InputEvent, click_position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Hex tile clicked at coordinates: q =", q, ", r =", r)
		emit_signal("hex_selected", q, r)

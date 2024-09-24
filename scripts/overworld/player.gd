extends Node3D

@export var move_speed = 2.0  # Speed at which the player moves between hexes
@export var hex_radius: float = 0.51  # Size of hex tiles
@export var camera_offset_distance: float = 6.0  # Distance from the camera to the player
@export var camera_height: float = 3.0  # Height of the camera relative to the player
@export var min_zoom: float = 1.5  # Minimum distance for zoom
@export var max_zoom: float = 10.0  # Maximum distance for zoom
@export var zoom_speed: float = 1.0  # Speed at which the camera zooms
@export var rotation_speed: float = 2.0  # Speed at which the camera rotates around the player
@export var turn_speed: float = 5.0  # Speed of player rotation

var target_position: Vector3
var is_moving: bool = false
var camera_angle: float = 0.0  # Camera rotation angle around the player

# Reference to the camera node
var camera: Camera3D

func _ready():
	# Set the initial position and reference the camera
	target_position = global_transform.origin
	camera = $Camera3D  # Assuming the Camera3D node is a child of this node
	camera.make_current()
	update_camera_position()

func _process(delta):
	# Handle player movement
	if is_moving:
		var direction = target_position - global_transform.origin
		var distance = direction.length()

		if distance > 0.1:
			direction = direction.normalized()
			global_transform.origin += direction * move_speed * delta

			# Rotate the player towards the movement direction
			rotate_towards_direction(direction, delta)
		else:
			global_transform.origin = target_position
			is_moving = false

	# Handle camera rotation input (left/right arrow keys)
	if Input.is_action_pressed("ui_left"):
		camera_angle -= rotation_speed * delta  # Rotate left
	elif Input.is_action_pressed("ui_right"):
		camera_angle += rotation_speed * delta  # Rotate right

	# Handle camera zoom with the mouse wheel
	if Input.is_action_just_pressed("ui_scroll_up"):
		camera_offset_distance = max(min_zoom, camera_offset_distance - zoom_speed)  # Zoom in
	elif Input.is_action_just_pressed("ui_scroll_down"):
		camera_offset_distance = min(max_zoom, camera_offset_distance + zoom_speed)  # Zoom out

	# Update camera position and make it look at the player
	update_camera_position()

# Move to a target hex, based on hex coordinates (q, r)
func move_to_hex(q: int, r: int):
	if is_moving:
		return  # Don't allow movement while already moving

	# Convert hex coordinates to world position
	target_position = hex_to_world_position(q, r)
	is_moving = true

# Rotate the player to face the movement direction
func rotate_towards_direction(direction: Vector3, delta: float):
	var target_rotation = direction.angle_to(Vector3.FORWARD)
	# Smoothly rotate towards the target direction (turn_speed controls how fast the rotation is)
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), turn_speed * delta)

# Convert hex coordinates to world position
func hex_to_world_position(q: int, r: int) -> Vector3:
	var x = hex_radius * 3.0 / 2.0 * q
	var z = hex_radius * sqrt(3) * (r + q / 2.0)
	return Vector3(x, 0, z)

# Update the camera's position and orientation
func update_camera_position():
	# Calculate the new camera position based on the rotation angle and zoom level
	var camera_x = camera_offset_distance * cos(camera_angle)
	var camera_z = camera_offset_distance * sin(camera_angle)
	var camera_target_position = global_transform.origin + Vector3(camera_x, camera_height, camera_z)

	# Smooth camera movement using linear interpolation (lerp)
	camera.global_transform.origin = camera.global_transform.origin.lerp(camera_target_position, 0.1)

	# Make the camera look at the player
	camera.look_at(global_transform.origin, Vector3.UP)

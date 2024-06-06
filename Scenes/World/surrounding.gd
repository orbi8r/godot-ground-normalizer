extends Node3D

@onready var player: Player = $Player

@onready var dodecahedron: Node3D = %Dodecahedron
@onready var rotation_marker: Marker3D = %RotationMarker

@onready var floor_rotation_timer: Timer = $Physical/RotationNodes/FloorRotationTimer

@export var lerp_speed := 5


func _process(delta: float) -> void:
	
	# Resets Player x and z rotations
	player.rotation = lerp(player.rotation, Vector3(0,player.rotation.y,0), delta * lerp_speed)

#region Dodecaheadron Rotation

func dodecahedron_rotate(cornernumber: int) -> void:
	
	if floor_rotation_timer.is_stopped():
		floor_rotation_timer.start()
		
		rotation_marker.global_position = player.global_position
		
		dodecahedron.rotate(
			Vector3(sin(deg_to_rad(-72 * (cornernumber-1))), 0, cos(deg_to_rad(72 * (cornernumber-1)))) ,deg_to_rad(63.4)
			)
		player.rotate(
			Vector3(sin(deg_to_rad(-72 * (cornernumber-1))), 0, cos(deg_to_rad(72 * (cornernumber-1)))) ,deg_to_rad(63.4)
			)
			
		dodecahedron.rotate(Vector3(0,1,0),deg_to_rad(36))
		player.rotate(Vector3(0,1,0),deg_to_rad(36))
		
		player.global_position = rotation_marker.global_position


func _on_corner_1_body_entered(body: Node3D) -> void:
	if body is Player:
		dodecahedron_rotate(1)

func _on_corner_2_body_entered(body: Node3D) -> void:
	if body is Player:
		dodecahedron_rotate(2)

func _on_corner_3_body_entered(body: Node3D) -> void:
	if body is Player:
		dodecahedron_rotate(3)

func _on_corner_4_body_entered(body: Node3D) -> void:
	if body is Player:
		dodecahedron_rotate(4)

func _on_corner_5_body_entered(body: Node3D) -> void:
	if body is Player:
		dodecahedron_rotate(5)

#endregion

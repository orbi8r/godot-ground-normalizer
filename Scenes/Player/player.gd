extends CharacterBody3D
class_name Player

#region Variables


# Mouse Sensitivity
@export var mouse_sensitivity := 0.085

# Player Speed
@export var walking_speed := 5.0
@export var sprinting_speed := 8.5
@export var crouching_speed := 3.0
@export var sliding_speed := 8.0

# Used for all movement Smoothening Lerps (lower is smoother)
@export var speed_smoothen := 6.0
@export var air_speed_smoothen := 1.5
var lerp_var = speed_smoothen

# Player Jump Speed
@export var walking_jump_velocity := 4.5
@export var sprinting_jump_velocity := 6.5

# Player Height
@export var head_height := 1.8
@export var crouch_head_height := 1.2

# Head for looking
@onready var head: Node3D = %Head
# Neck for head bobbing animations
@onready var neck: Node3D = %Neck
# Eyes is Camera3D
@onready var eyes: Camera3D = %Eyes


# Body State nodes
@onready var body_collision_standing: CollisionShape3D = %BodyCollision_Standing
@onready var body_collision_crouching: CollisionShape3D = %BodyCollision_Crouching
# Checks if Player can UnCrouch
@onready var check_above_head: RayCast3D = %CheckAboveHead

# Animation Player
@onready var animated: AnimationPlayer = %Animated

# Item Detector and Markers
@onready var marker_hand: Marker3D = %MarkerHand
@onready var item_detector: RayCast3D = %ItemDetector

# Item Picked
@onready var object_picked_name: Label = %ObjectPickedName



# Timing for Player Slide (For some reason Timer Node doesnt work well)
@export var slide_end_time := 1.2
var slide_time = slide_end_time

# Current Speed Variables
var current_jump_velocity = walking_jump_velocity
var current_speed = walking_speed

# Last Frame velocity
var last_frame_velocity = Vector2.ZERO

# Player Facing direction
var direction := Vector3.ZERO
# Sliding
var slide_vector := Vector2.ZERO

# Gravity? Duh
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player States
var is_walking := false
var is_crouching := false
var is_sprinting := false
var is_sliding := false	

# Head bobbing constants
@export var sprinting_speed_head_bobbing := 27.0
@export var walking_speed_head_bobbing := 20.0
@export var crouching_speed_head_bobbing := 12.0

var sprinting_intentsity_head_bobbing = 0.22
var walking_intentsity_head_bobbing = 0.15
var crouching_intentsity_head_bobbing = 0.07

# Head bobbing tracking variables
var head_bobbing_vector := Vector2.ZERO
var head_bobbing_index := 0.0
var head_bobbing_current_intensity := 0.0

# Head rotation while sliding
@export var sliding_angle_head_rotation := 7.0

# Variables to know about interaction objects
var picked_object
@export var pull_power := 4

#endregion


# Initialization
func _ready() -> void:
	# Captures cursor inside window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

# On any Input
func _input(event: InputEvent) -> void:
	# Head Rotation via Mouse
	if event is InputEventMouseMotion:
		
		# Rotating LeftRight
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		# Rotating UpDown
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		
	if Input.is_action_just_pressed("left_click"):
		if picked_object == null:
			# Fetch the object that raycast interacted
			var collided_object = item_detector.get_collider()
			
			if collided_object != null and collided_object is RigidBody3D:
				picked_object = collided_object
				
		else :
			picked_object = null


# Physics processes
func _physics_process(delta: float) -> void:
	
	# Checks lerp smoothen variables
	if is_on_floor():
		lerp_var = speed_smoothen
	else:
		lerp_var = air_speed_smoothen
		#Adds Gravity
		velocity.y -= gravity * delta
	
	# Get the input direction and handle the movement/deceleration.
	var input_direction := Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = lerp(direction,(transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized(),lerp_var*delta)
	
	# Changes speed,jump & height when changing movement states
	# Crouching
	if Input.is_action_pressed("Crouch") or is_sliding:
		
		# Moves head down to Crouch View
		head.position.y = lerp(head.position.y,crouch_head_height,lerp_var *delta)
		
		# Changes body height down
		body_collision_standing.disabled = true
		body_collision_crouching.disabled = false
		
		# Crouch speed
		if is_on_floor(): # {To prevent air/jump crouch speed change}
			current_speed = lerp(current_speed, crouching_speed, lerp_var * delta)
		
		
		# Sliding check
		if is_sprinting and input_direction != Vector2.ZERO and is_on_floor():
			is_sliding = true
			slide_vector = input_direction
			slide_time = slide_end_time
		
		# Player States
		is_walking = false
		is_crouching = true
		is_sprinting = false
	
	# Not Crouching
	elif !check_above_head.is_colliding():
		
		# Moves head back up from Crouch View
		head.position.y = lerp(head.position.y, head_height, lerp_var * delta)
		
		# Changes body height back up
		body_collision_standing.disabled = false
		body_collision_crouching.disabled = true
		
		# Sprinting
		if Input.is_action_pressed("Sprint"):
			#Sprint speed/jump
			current_speed = lerp(current_speed, sprinting_speed, lerp_var * delta)
			current_jump_velocity = sprinting_jump_velocity
			
			# Player States
			is_walking = false
			is_crouching = false
			is_sprinting = true
			
		# Not Sprinting
		else:
			#Walking speed/jump
			current_speed = lerp(current_speed, walking_speed, lerp_var * delta)
			current_jump_velocity = walking_jump_velocity 
			
			# Player States
			is_walking = true
			is_crouching = false
			is_sprinting = false


	# Handle Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = current_jump_velocity
		animated.play("Jump")
		
		
	# Overrides user input while sliding
	if is_sliding:
		direction = (transform.basis * Vector3(slide_vector.x,0,slide_vector.y)).normalized()
		# Keeps Slide Time
		slide_time -= delta
		
	# Stops the Slide Timer
	if slide_time <= 0.0 or !is_on_floor():
		is_sliding = false
	
	#Head bobbing calculator
	if is_sprinting:
		# Intense Head bobbing while sprinting
		head_bobbing_current_intensity = sprinting_intentsity_head_bobbing
		head_bobbing_index += sprinting_speed_head_bobbing * delta
		
	elif is_walking:
		# Normal Head bobbing while walking
		head_bobbing_current_intensity = walking_intentsity_head_bobbing
		head_bobbing_index += walking_speed_head_bobbing * delta
		
	elif is_crouching:
		# Mild Head bobbing while crouching
		head_bobbing_current_intensity = crouching_intentsity_head_bobbing
		head_bobbing_index += crouching_speed_head_bobbing * delta
		
	# Falling back to ground (after jump) Animation
	if is_on_floor():
		if last_frame_velocity.y < -7:
			animated.play("Drop_High")
		elif last_frame_velocity.y < -5:
			animated.play("Drop_Medium")
		elif last_frame_velocity.y < -3:
			animated.play("Drop_Low")
			
		
	# Camera Movements
	# Head Bobbing
	if is_on_floor() and input_direction != Vector2.ZERO:
		# Adds Headbobbing to Neck Node
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = cos(head_bobbing_index/2)
		
		neck.position.y = lerp(neck.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity /2.0) , speed_smoothen*delta)
		neck.position.x = lerp(neck.position.x, head_bobbing_vector.x * head_bobbing_current_intensity , speed_smoothen*delta)
	
	else:
		# Resets the camera
		neck.position.y = lerp(neck.position.y, 0.0, speed_smoothen*delta)
		neck.position.x = lerp(neck.position.x, 0.0, speed_smoothen*delta)
	
	# Sliding
	if is_sliding:
		# Tilts head while sliding
		neck.rotation.z = lerp(neck.rotation.z, deg_to_rad(sliding_angle_head_rotation), lerp_var*delta)
		
		# Custom Slide speeds
		current_speed = (slide_time + 0.4) * sliding_speed # Used SLIDETIME so that it starts Fast and ends slow
	
	else:
		# Resets the camera
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, lerp_var*delta)
		neck.rotation.z = lerp(neck.rotation.z, 0.0, lerp_var*delta)
		
	
	if direction:
		# Adds velocity Vectors
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		# Moves velocity Vectors
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
		
	# Keeps a record of the velocity this frame, for next one
	last_frame_velocity = velocity
	
	
	
	# For Picking up Objects
	if picked_object != null:
		# Gives the Object name
		object_picked_name.text = str(picked_object)
		
		# Gets object position, orientation and moves it
		var object_position = picked_object.global_transform.origin
		var hand_position = marker_hand.global_transform.origin
		# Linear velocity will be the Vector3 connecting the above two variables
		picked_object.set_linear_velocity((hand_position-object_position)*pull_power)
		
	else:
		object_picked_name.text = ""
		
		
	
	# Apply all Velocities
	move_and_slide()

extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAX_PITCH_UP = deg_to_rad(80)
const MAX_PITCH_DOWN = deg_to_rad(-80)

@export var mouse_sensitivity_x := 5
@export var mouse_sensitivity_y := 7

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _input(event):
	if event is InputEventMouseButton:
		handle_mouse_button(event)
		return
	if event is InputEventMouseMotion:
		handle_mouse_move(event)
		return


func handle_mouse_button(event: InputEventMouseButton):
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func handle_mouse_move(event: InputEventMouseMotion):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var d_twist = -event.relative.x * 0.0001 * mouse_sensitivity_x
	var d_pitch = -event.relative.y * 0.0001 * mouse_sensitivity_y
	
	rotate_y(d_twist)
	$CameraPitchPivot.rotation.x = clamp(
		$CameraPitchPivot.rotation.x + d_pitch,
		MAX_PITCH_DOWN,
		MAX_PITCH_UP
	)

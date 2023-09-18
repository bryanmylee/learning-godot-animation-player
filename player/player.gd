extends CharacterBody3D


const SPEED_WALK = 2.8
const SPEED_RUN = 5.0
const ACCELERATION = 5
const DECELERATION_GROUND = 10
const DECELERATION_AIR = 1
const JUMP_VELOCITY = 4.5
const MAX_PITCH_UP = deg_to_rad(80)
const MAX_PITCH_DOWN = deg_to_rad(-80)

@export var mouse_sensitivity_x := 5
@export var mouse_sensitivity_y := 7

@onready var camera_pitch_pivot := $CameraPitchPivot
@onready var animation_player := $Visuals/mixamo_base/AnimationPlayer
@onready var visuals := $Visuals

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


var move_direction := Vector3.FORWARD
var move_speed := SPEED_WALK
var is_running := false
var is_kicking := false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func handle_animation_kick_end():
	is_kicking = false

func _physics_process(delta):
	
	if Input.is_action_just_pressed("action_kick"):
		if animation_player.current_animation != "kick":
			animation_player.play("kick")
			is_kicking = true
	
	is_running = Input.is_action_pressed("mod_run")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("move_jump") \
		and is_on_floor() \
		and not is_kicking:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward") \
		if not is_kicking else Vector2.ZERO
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	move_direction = move_direction.slerp(direction, 8 * delta)
	visuals.look_at(move_direction + position)
	
	# Handle movement acceleration
	move_speed = move_toward(move_speed, SPEED_RUN if is_running else SPEED_WALK, ACCELERATION * delta)
	var move_animation := "running" if is_running else "walking" 
	
	if not direction.is_zero_approx():
		if animation_player.current_animation != move_animation:
			animation_player.play(move_animation)
		
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		if not is_kicking \
			and animation_player.current_animation != "idle":
			animation_player.play("idle")
		
		var deceleration := DECELERATION_GROUND if is_on_floor() else DECELERATION_AIR
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
	
	move_and_slide()


func _input(event):
	if event is InputEventMouseButton:
		handle_mouse_button(event)
		return
	if event is InputEventMouseMotion:
		handle_mouse_motion(event)
		return


func handle_mouse_button(event: InputEventMouseButton):
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func handle_mouse_motion(event: InputEventMouseMotion):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var d_twist = -event.relative.x * 0.0001 * mouse_sensitivity_x
	var d_pitch = -event.relative.y * 0.0001 * mouse_sensitivity_y
	
	rotate_y(d_twist)
	visuals.rotate_y(-d_twist)
	
	camera_pitch_pivot.rotation.x = clamp(
		camera_pitch_pivot.rotation.x + d_pitch,
		MAX_PITCH_DOWN,
		MAX_PITCH_UP
	)

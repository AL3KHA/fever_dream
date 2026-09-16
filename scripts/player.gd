extends CharacterBody3D

@onready var animplayer = $AnimationPlayer
@onready var animtree = $AnimationTree
@onready var fpp_location = $Armature/Skeleton3D/BoneAttachment3D/BoneAttachment3D/Node3D
@onready var fpp_camera = $Camera3D
@onready var tpp_pivot_location = $tpp_pivot_ocation
@onready var tpp_pivot = $tpp_pivot_ocation/tpp_pivot
@onready var tpp_camera = $tpp_pivot_ocation/tpp_pivot/SpringArm3D/SpringArm3D/Camera3D
@onready var head = $Armature/Skeleton3D/BoneAttachment3D/BoneAttachment3D
@onready var collision = $CollisionShape3D
@onready var edge_detection = $"edge detection"
@onready var edge_detection2 = $"edge detection2"
@onready var armature = $Armature
@onready var spine1 = $Armature/Skeleton3D/BoneAttachment3D2
@onready var snow_footsteps = "res://sounds/footsteps/snow/"
@onready var left_area_3d: Area3D = $Armature/Skeleton3D/left_foot/left_area3d
@onready var right_area_3d: Area3D = $Armature/Skeleton3D/right_foot/right_area3d


@onready var running_jump_forward: AnimationNodeStateMachinePlayback = animtree.get("parameters/normal_state/jumping/jumping forward/run jumping/running jump forward/playback")

@export var WALKING_SPEED: float = 2.25
@export var SPRINTING_SPEED: float = 7.0
@export var CROUCHING_SPEED: float = 1.7
@export var JUMP_VELOCITY = 4.5
@export var strafe_acceleration: int = 4

var sensitivity = 0.008
var speed = WALKING_SPEED
var target_speed
var current_speed: Vector2 = Vector2.ZERO

#player states
var normal_state: bool = true
var big_hammer_state: bool
var mma_state: bool
var rifle_State: bool
var walking: bool = true
var sprinting: bool
var crouching: bool
var climbing: bool
var left_foot_contact: bool
var right_foot_contact: bool

#animtree positions
var state_switch: Vector2 = Vector2(0.0, -1.0)
var walking_switch: Vector2 = Vector2(0.0, 0.0)
var jumping_direction: float
var jump_sprinting: float

var random = RandomNumberGenerator.new()

func _ready() -> void:
	left_area_3d.body_entered.connect(left_step_detected)
	right_area_3d.body_entered.connect(right_step_detected)

func _input(event: InputEvent) -> void:
	#handling camera change
	if event.is_action_pressed("camera_change"):
		if fpp_camera.current == true:
			fpp_camera.current = false
			tpp_camera.current = true
		elif tpp_camera.current == true:
			tpp_camera.current = false
			fpp_camera.current = true

	#handling jumping direction
	#if event.is_action_pressed("back") and is_on_floor():
		#jumping_direction = -1
	#elif not event.is_action_pressed("back") and is_on_floor():
		#jumping_direction = 0
	if !is_on_floor():
		walking_switch = Vector2(0, 1)
		jumping_direction = 1

	# Handling animation states
	if event.is_action_pressed("sprint"):
		sprinting = true
		crouching = false
		walking = false
	if event.is_action_released("sprint"):
		sprinting = false
		crouching = false
		walking = true
	if event.is_action_pressed("crouch") and !sprinting:
		crouching = true
		sprinting = false
		walking = false
	if event.is_action_released("crouch") and !sprinting:
		crouching = false
		sprinting = false
		walking = true

func _unhandled_input(event: InputEvent) -> void:
	# Handling footstep sounds
	

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			if !climbing:
				rotate_y(-event.relative.x * sensitivity)
			fpp_camera.rotate_x(-event.relative.y * sensitivity)
			fpp_camera.rotation.x = clamp(fpp_camera.rotation.x, deg_to_rad(-56), deg_to_rad(45))
			fpp_camera.rotation.y = clamp(fpp_camera.rotation.y, deg_to_rad(0), deg_to_rad(0))
			fpp_camera.rotation.z = clamp(fpp_camera.rotation.z, deg_to_rad(0), deg_to_rad(0))
			head.rotate_x(event.relative.y * sensitivity)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-56), deg_to_rad(45))
			head.rotation.y = clamp(head.rotation.y, deg_to_rad(0), deg_to_rad(0))
			head.rotation.z = clamp(head.rotation.z, deg_to_rad(0), deg_to_rad(0))
			tpp_pivot.rotate_x(-event.relative.y * sensitivity)
			tpp_pivot.rotation.x = clamp(tpp_pivot.rotation.x, deg_to_rad(-56), deg_to_rad(45))
			tpp_pivot.rotation.y = clamp(tpp_pivot.rotation.y, deg_to_rad(0), deg_to_rad(0))
			tpp_pivot.rotation.z = clamp(tpp_pivot.rotation.z, deg_to_rad(0), deg_to_rad(0))

func _physics_process(delta: float) -> void:

	# Respawn for debbuging
	if global_position.y <= -20:
		$".".global_position = Vector3(0, 0.8, 5)

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handling climbing
	if not is_on_floor():
		if Input.is_action_pressed("jump") and edge_detection.is_colliding() and !edge_detection2.is_colliding():
			animplayer.play("climbing")
			animtree.active = false
			velocity = Vector3.ZERO
			global_position.y += 1.3
			armature.position.y = -2.3
			global_position += global_transform.basis.z * -0.4
			armature.position.z = .2
	if animplayer.is_playing() and animplayer.current_animation == "climbing":
		climbing = true
	if not animplayer.is_playing() and not animplayer.current_animation == "climbing":
		climbing = false
		armature.position.y = 0.0
		armature.position.z = 0.0
		animtree.active = true	

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and !climbing:
		if !Input.is_action_pressed("back"):
			velocity.y = JUMP_VELOCITY
			if Input.is_action_pressed("sprint"):
				pass
			elif !Input.is_action_pressed("sprint"):
				pass
		elif Input.is_action_pressed("back"):
			velocity.y = JUMP_VELOCITY / 3
			velocity += global_transform.basis.z.normalized() * JUMP_VELOCITY * 2

	# Handling animations switches
	if is_on_floor() and not Input.is_action_just_pressed("jump"):
		if sprinting == true:
			jump_sprinting = 1
			speed = SPRINTING_SPEED
			walking_switch = Vector2(-1, 0)
			collision.shape.height = 1.7
			collision.shape.radius = 0.2
			collision.position.y = 0.85
		elif crouching == true:
			jump_sprinting = -1
			speed = CROUCHING_SPEED
			walking_switch = Vector2(1, 0)
			collision.shape.height = 1.0625
			collision.shape.radius = 0.2
			collision.position.y = 0.55
		elif walking == true:
			jump_sprinting = -1
			speed = WALKING_SPEED
			walking_switch = Vector2(0, -1)
			collision.shape.height = 1.7
			collision.shape.radius = 0.2
			collision.position.y = 0.85

	# Handling camera locations
	fpp_camera.global_position = fpp_location.global_position
	tpp_pivot_location.global_position = tpp_pivot_location.global_position.move_toward(spine1.global_position, strafe_acceleration * delta / 5)
	#tpp_pivot_location.global_position = spine1.global_position

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor() and !climbing and !Input.is_action_just_pressed("jump"):
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 12.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 12.0)

	target_speed = Vector2(-input_dir.x, input_dir.y).normalized()
	current_speed = current_speed.move_toward(-target_speed, strafe_acceleration * delta)

	var state_switch_smoothed: Vector2 = Vector2(0.0, -1.0)
	var walking_switch_smoothed: Vector2 = Vector2(0.0, 0.0)

	#setting animtree states
	state_switch_smoothed = state_switch_smoothed.move_toward(state_switch, strafe_acceleration * delta * 5)
	animtree.set("parameters/blend_position", state_switch_smoothed)
	walking_switch_smoothed = walking_switch_smoothed.move_toward(walking_switch, strafe_acceleration * delta * 5)
	animtree.set("parameters/normal_state/blend_position", walking_switch_smoothed)
	#setting animation direction
	animtree.set("parameters/normal_state/walking/blend_position", current_speed)
	animtree.set("parameters/normal_state/running/blend_position", current_speed)
	animtree.set("parameters/normal_state/crouching/blend_position", current_speed)
	animtree.set("parameters/normal_state/jumping/jumping forward/walk jumping/blend_position", current_speed)
	animtree.set("parameters/normal_state/jumping/jumping forward/run jumping/blend_position", current_speed)
	animtree.set("parameters/normal_state/jumping/jumping back/blend_position", current_speed)

	move_and_slide()

func left_step_detected(body: Node3D):
	random.randomize()
	var step = random.randi_range(1, 16)
	var step_sound_path = "res://sounds/footsteps/snow/" + str(step) + ".mp3"
	var step_sound = load(step_sound_path)
	$Armature/Skeleton3D/left_foot/AudioStreamPlayer3D.stream = step_sound
	$Armature/Skeleton3D/left_foot/AudioStreamPlayer3D.play()
	print("left" + str(step))

func right_step_detected(body: Node3D):
	random.randomize()
	var step = random.randi_range(1, 16)
	var step_sound_path = "res://sounds/footsteps/snow/" + str(step) + ".mp3"
	var step_sound = load(step_sound_path)
	$Armature/Skeleton3D/right_foot/AudioStreamPlayer3D.stream = step_sound
	$Armature/Skeleton3D/right_foot/AudioStreamPlayer3D.play()
	print("right" + str(step))

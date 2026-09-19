extends Node

@onready var player = $player
@onready var advanced_DOF = $player/Camera3D/SpringArm3D
@onready var world_enviroment = $WorldEnvironment

var far_distance_smoothed: float
var near_distance_smoothed: float

@export var DOF_speed: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var dof_distance: float = advanced_DOF.get_hit_length()
	var far_distance: float
	var near_distance: float = dof_distance
	if dof_distance <= 100:
		far_distance = dof_distance
	if dof_distance >= 95:
		far_distance = 8192.0
	print(dof_distance, " ", far_distance)
	far_distance_smoothed = lerp(far_distance_smoothed, far_distance, delta * DOF_speed)
	near_distance_smoothed = lerp(near_distance_smoothed, near_distance, delta * DOF_speed)
	world_enviroment.camera_attributes.dof_blur_far_distance = far_distance_smoothed
	world_enviroment.camera_attributes.dof_blur_far_transition = far_distance_smoothed * 2
	world_enviroment.camera_attributes.dof_blur_near_distance = near_distance_smoothed / 2
	world_enviroment.camera_attributes.dof_blur_near_transition = near_distance_smoothed / 2

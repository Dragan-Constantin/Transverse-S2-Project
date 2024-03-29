extends CharacterBody2D

signal balistaOn
signal balistaOff



const SPEED = 150.0
const RUN_SPEED = 300.0
const ACCELERATION = 500.0
const JUMP_VELOCITY = -500.0
const GLIDE_GRAVITY = 50.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#const SpotScene = preload("res://Scenes/utilities/Spot.tscn")

const states = {
	idle = 0,
	attached = 1,
	launched = 2
}
const trajectorySpotCount = 5
const trajectoryTimeStep = .1
const spotScene = preload("res://Scenes/utilities/Spot.tscn")

var flyingSpeed = 0
var state = states.idle
var is_glide = false
var is_crouch = false
 
var launchSpeed = 500
var angle = 0
const minAngle = -45
const maxAngle = 45
const minPower = 600
const maxPower = 1000

var linearVelocity
var angularVelocity

@onready var collision_shape = $CollisionShape2D
@onready var trajectory_node = $trajectory
@onready var default_crouch_extents = collision_shape.shape.extents
@onready var crouch_extents = Vector2(default_crouch_extents.x, default_crouch_extents.y)
@onready var animated_sprite = $Sprite
@onready var jumpSFX: AudioStreamPlayer2D = $SFX_Player2D/Jump_SFX
@onready var crouchSFX: AudioStreamPlayer2D = $SFX_Player2D/Crouch_SFX
@onready var walkSFX: AudioStreamPlayer2D = $SFX_Player2D/Walk_SFX

func _input(event):
	if event.is_action_pressed("pause_ui"):
		$PauseMenuUI.pause()

func _physics_process(delta: float) -> void:
	handle_states(delta)
	
	
func cameraZoom(delta):
	$PlayerCamera.zoom_x = lerp(2.0, $PlayerCamera.zoom_x, pow(2, -30 * delta))
	$PlayerCamera.zoom_y = lerp(2.0, $PlayerCamera.zoom_y, pow(2, -30 * delta))
	
func cameraUnZoom(delta):
	$PlayerCamera.zoom_x = lerp(1.0, $PlayerCamera.zoom_x, pow(2, -30 * delta))
	$PlayerCamera.zoom_y = lerp(1.0, $PlayerCamera.zoom_y, pow(2, -30 * delta))

func handle_states(delta):
	if is_on_floor():
		if Input.is_action_just_pressed("toggle_launch"):
			delete_spots()
			if state == states.idle: 
				state = states.attached
				angle = 0
				launchSpeed = 600
				
				emit_signal("balistaOn")
			elif state == states.attached: 
				emit_signal("balistaOff")
				state = states.idle
			velocity = Vector2.ZERO
	match state:
		states.idle:
			handle_movement(delta)
			cameraZoom(delta)
		states.launched, states.attached:
			delete_spots()
			_integrate_forces(delta)
			cameraUnZoom(delta)
	$PlayerCamera.set_zoom(Vector2($PlayerCamera.zoom_x, $PlayerCamera.zoom_y))
	$Node/Control/Cannon.visible = state != states.idle
	$Node/Control/Ballista.visible = $Node/Control/Cannon.visible
func _integrate_forces(delta):
	$Node/Control/Cannon.rotation_degrees = angle
	match state:
		states.attached:
			$Node/Control.position = position
			animated_sprite.flip_h = angle < 0
			var angleVariation = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			angle += angleVariation * delta * 30
			var powerVariation = Input.get_action_strength("launch_speed_up") - Input.get_action_strength("launch_speed_down")
			launchSpeed += powerVariation * delta * 300
			
			angle = border(angle, minAngle, maxAngle)
			launchSpeed = border(launchSpeed, minPower, maxPower)
			linearVelocity = launchSpeed*sin(angle/180*PI)
			angularVelocity = -launchSpeed*cos(angle/180*PI)
			velocity = Vector2(linearVelocity, angularVelocity)
			draw_trajectory(velocity)
			
			if Input.is_action_just_pressed("launch"): 
				state = states.launched
				position = Vector2(position.x, position.y-1)
		states.launched:
			velocity.y = velocity.y + gravity * delta
			flyingSpeed = velocity.x
			move_and_slide()
			if is_on_wall() and not is_on_floor():
				velocity.x = -0.5* flyingSpeed
				animated_sprite.flip_h = velocity.x < 0
			if is_on_floor():
				state = states.idle
				emit_signal("balistaOff")
				velocity = Vector2.ZERO
		_: pass
	
func draw_trajectory(V):
	var g = gravity / 2
	for i in range(1, trajectorySpotCount + 1):
		var t = i * trajectoryTimeStep
		var x = V.x * t
		var y = (g * t*t + V.y * t)
		draw_spot(Vector2(x,y))

func draw_spot(spot_position):
	var spot = spotScene.instantiate()
	spot.position = spot_position
	spot.z_index = z_index + 1
	trajectory_node.add_child(spot)

func delete_spots():
	for spot in trajectory_node.get_children():
		spot.queue_free()
		
func border(myVar, minVal, maxVal):
	if myVar > maxVal: myVar = maxVal + 0.1
	elif myVar < minVal: myVar = minVal - 0.1
	return myVar
	







func handle_movement(delta) -> void:
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if input_x == 0:
		velocity.x = lerp(0.0, velocity.x, pow(2, -50 * delta))
	var speed = 0
	if not(is_crouch):
		speed = SPEED
		if Input.is_action_pressed("run"):
			speed = RUN_SPEED
	velocity.x += input_x * ACCELERATION * delta
	velocity.x = clamp(velocity.x, -speed, speed)
	# if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
	# 	if velocity.x != 0 and is_on_floor():
	# 		$SFX_Player2D/Timer.start()
	# 		if $SFX_Player2D/Timer.time_left==0:
	# 			walkSFX.play()

		
	handle_crouching()
	handle_jumping()
	handle_gliding()
	apply_gravity()
	move_and_slide()
	update_animation()


func handle_jumping() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()

func handle_crouching() -> void:
	if Input.is_action_just_pressed("crouch"):
		animated_sprite.play("crouch")
	if Input.is_action_pressed("crouch") and is_on_floor():
		crouchSFX.play()
		is_crouch = true
	else:
		is_crouch = false
	update_crouch_collision()

func handle_gliding() -> void:
	if Input.is_action_just_pressed("jump") and is_falling() and !is_on_floor():
		is_glide = true
	is_glide = Input.is_action_pressed("jump") and !is_on_floor() and is_falling() and is_glide

func apply_gravity() -> void:
	var gravity_to_apply = gravity
	if velocity.y <= 0:
		if  Input.is_action_pressed("jump"):
			gravity_to_apply /= 1.5
	elif is_glide:
		gravity_to_apply = GLIDE_GRAVITY
	velocity.y += gravity_to_apply * get_physics_process_delta_time()

func jump() -> void:
	velocity.y = JUMP_VELOCITY
	jumpSFX.play()


func is_falling() -> bool:
	return velocity.y > 1

func update_crouch_collision() -> void:
	if is_crouch:
		collision_shape.shape.extents = crouch_extents
	else:
		collision_shape.shape.extents = default_crouch_extents

func update_animation() -> void:
	if not is_crouch:
		if is_on_floor():
			if velocity.x == 0 or is_on_wall():
				animated_sprite.play("idle")
			else:
				if Input.is_action_pressed("run"):
					animated_sprite.play("run")
				else:
					animated_sprite.play("walk")
		elif is_glide:
			animated_sprite.play("plane")
		else:
			if velocity.y < 0:
				animated_sprite.play("jump")
			else:
				animated_sprite.play("fall")
		if velocity.x:
			animated_sprite.flip_h = velocity.x < 0


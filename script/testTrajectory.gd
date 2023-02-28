extends KinematicBody2D


enum {
	STATE_IDLE,
	STATE_ATTACHED,
	STATE_LAUNCHED
}

const physics = { "gravity_factor": 20, "jumpforce": -300 }
const minAngle = -60
const maxAngle = 60
const minPower = 1000
const maxPower = 1500


export(int) var blockSize= 128
export(int, 5, 15) var trajectorySpotCount = 10
export(float, 0.1, 1, 0.1) var trajectoryTimeStep = .1
export(PackedScene) var spotScene

var state = STATE_IDLE
var launchSpeed = 1000
var angle = 30
var linearVelocity
var angularVelocity
var velocity = Vector2.ZERO


func _integrate_forces(delta):
	# IMPLEMENT STATES
	match state:
		STATE_ATTACHED: 
			var angleVariation = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
			angle += angleVariation * delta * 30
			var powerVariation = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
			launchSpeed += powerVariation * delta * 300
			
			angle = border(angle, minAngle, maxAngle)
			launchSpeed = border(launchSpeed, minPower, maxPower)
			
			if Input.is_action_just_pressed("ui_accept"): 
				state = STATE_LAUNCHED
				move_and_slide(Vector2(0,-.001))
			linearVelocity = launchSpeed*sin(angle/180*PI)
			angularVelocity = -launchSpeed*cos(angle/180*PI)
			velocity = Vector2(linearVelocity, angularVelocity)
			draw_trajectory(velocity)
						
		_: pass
	if state == STATE_LAUNCHED:
		if is_on_floor():
			state = STATE_IDLE
			velocity = Vector2.ZERO
			angle = 30
			launchSpeed = 1000
		velocity.y = velocity.y + physics.gravity_factor * delta * 60
		velocity = move_and_slide(Vector2(velocity.x * delta * 60, velocity.y * delta * 60), Vector2.UP)
	debug(state, delta)

func _physics_process(delta):
	delete_spots()
	if  is_on_floor():
		if Input.is_action_just_pressed("toggle_launch"):
			if state == STATE_IDLE: state = STATE_ATTACHED
			elif state == STATE_ATTACHED: state = STATE_LAUNCHED
	match state:
		STATE_IDLE:
			velocity = move_and_slide(velocity, Vector2.UP)
			velocity.y = velocity.y + physics.gravity_factor
		STATE_LAUNCHED, STATE_ATTACHED: _integrate_forces(delta)
		_: pass
func draw_trajectory(V):
	var g = physics.gravity_factor * 30
	for i in range(1, trajectorySpotCount + 1):
		var t = i * trajectoryTimeStep
		var x = V.x * t
		var y = (g * t*t + V.y * t)
		draw_spot(Vector2(x,y))

func draw_spot(position):
	var spot = spotScene.instance()
	spot.position = position
	$trajectory.add_child(spot)

func delete_spots():
	for spot in $trajectory.get_children():
		spot.queue_free()

func border(myVar, minVal, maxVal):
	if myVar > maxVal: myVar = maxVal + 0.1
	elif myVar < minVal: myVar = minVal - 0.1
	return myVar
	
func debug(variable, delta):
	var fps = 1/delta
	print("%s" % variable, " | ",  "%4.2f" % fps)

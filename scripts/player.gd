class_name Player extends CharacterBody2D

#signals
signal jumping
signal dashing

var player_size
#gravity
var gravity_acceleration : float = 3840
var max_velocity = 1000
var sliding_grav = gravity_acceleration * 0.05
#player movement variables
var face_dir: int = 1
var speed: float = 600
var normal_speed: float = 600
var dashing_speed: float = 1200
var deceleration: float = 3000
var dir
var acceleration: float = 2800
var turning_acceleration: float = 9600
#jump variables
var jump_force : float = 1600
var jump_cut : float = 0.25
var jump_gravity_max : float = 500
var jump_hang_treshold : float = 2.0
var jump_hang_gravity_mult : float = 0.1
var wall_pushback: float = 1300
#reference to raycast that is used for earth abillity
@onready var raycast_2d: MainRaycast = $"../Raycast2D"
#raycasts that check if both are on a wall allow you to wall jump
@onready var bottom_raycast: RayCast2D = %BottomRaycast
@onready var top_raycast: RayCast2D = %TopRaycast
#character animations
@onready var animations: AnimatedSprite2D = %animations
#display debuggers
@onready var state_label: Label = %StateLabel
@onready var label: Label = %Label
@onready var element: Label = %Element

#players collision shape
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
#timers
@onready var cooldown: Timer = %Cooldown
@onready var jump_buffer: Timer = %JumpBuffer
@onready var coyote_timer: Timer = %CoyoteTimer
@onready var wall_jump_delay: Timer = %WallJumpDelay
@onready var end_dashing: Timer = %EndDashing

#earth abillity variables
var elements: Array = ["earth", "water", "fire", "air"]
var element_index = 0
var current_element: String
#state variables
enum States {IDLE, RUN, AIR, SLIDING, CASTING, FALL}
static var current_State = States.IDLE

#checkpoint
var current_positon: Vector2 = Vector2(453,520)


func _ready() -> void:
	#store starting collision size so we can change it to it after dashing is finished
	player_size = collision_shape_2d.shape.extents.y


func _physics_process(delta: float) -> void:
	#display debuggers
	state_label.text = str(States.keys()[current_State])
	element.text = str(current_element)
	label.text = str(face_dir)
	#rotates between the 4 elements
	change_element()
	#handles movement input
	movement(delta)
	#gravity control
	apply_gravity(delta)
	#state manager
	match current_State:


		States.IDLE:
			animations.play("idle")
			#state changes
			if velocity.x != 0:
				change_state(States.RUN)
			if Input.is_action_pressed("jump"):
				emit_signal("jumping")
				change_state(States.AIR)
			if !is_on_floor():
				change_state(States.AIR)
			if Input.is_action_just_pressed("abillity") and GlobalTimer.time_left == 0:
				if current_element == "water":
					emit_signal("dashing")
				change_state(States.CASTING)


		States.RUN:
			animations.play("run")
			#state changes
			if velocity.x == 0:
				change_state(States.IDLE)
			if Input.is_action_pressed("jump"):
				emit_signal("jumping")
				change_state(States.AIR)
			if !is_on_floor():
				coyote_timer.start()
				change_state(States.AIR)
			if Input.is_action_just_pressed("abillity") and GlobalTimer.time_left == 0:
				if current_element == "water":
					emit_signal("dashing")
				change_state(States.CASTING)


		States.AIR:
			#jump buffer from wall 
			if Input.is_action_just_pressed("jump") and wall_jump_delay.time_left != 0:
				emit_signal("jumping")
			#coyote timer jump
			if Input.is_action_just_pressed("jump") and coyote_timer.time_left != 0:
				emit_signal("jumping")
			#if jump is released lower the jump
			if Input.is_action_just_released("jump"):
				velocity.y -= (jump_cut * velocity.y)
			#fall and jump animation setting
			if velocity.y > 0:
				animations.play("fall")
			if velocity.y < 0:
				animations.play("jump")
			#state changes
			if is_on_floor() and velocity.x == 0:
				change_state(States.IDLE)
			if is_on_floor() and velocity.x != 0:
				change_state(States.RUN)
			if is_on_wall_only() and dir != 0:
				velocity.y = 0
				change_state(States.SLIDING)
			if Input.is_action_just_pressed("abillity") and GlobalTimer.time_left == 0:
				if current_element == "water":
					emit_signal("dashing")
				change_state(States.CASTING)


		States.SLIDING:
			#checks which direction you are holding down
			#and pushes you away from the wall to the opposite direction
			if Input.is_action_just_pressed("jump") and bottom_raycast.is_colliding() and top_raycast.is_colliding():
				if dir == 1:
					emit_signal("jumping")
					velocity.x += -wall_pushback
				elif dir == -1:
					emit_signal("jumping")
					velocity.x += wall_pushback
				else:
					pass
		
			#state changes
			if is_on_floor() and velocity.x == 0:
				change_state(States.IDLE)
			if is_on_floor() and velocity.x != 0:
				change_state(States.RUN)
			if dir == 0 and is_on_wall_only():
				change_state(States.AIR)
				wall_jump_delay.start()
			if !is_on_floor() and !is_on_wall():
				change_state(States.AIR)
			if Input.is_action_just_pressed("abillity") and GlobalTimer.time_left == 0:
				if current_element == "water":
					emit_signal("dashing")
				change_state(States.CASTING)


		States.CASTING:

			match current_element:
				"earth":
					%animations.play("abillity")
					#clean up either pillar or box to make sure there is always only one 
					get_tree().call_group("pillars", "queue_free")
					get_tree().call_group("box", "queue_free")
					#start cooldown
					GlobalTimer.start()
					#if you click near the ground summons a pillar from it that doesnt move but is taller then box
					if raycast_2d.is_colliding():
						var new_pillar = preload("res://scenes/pillar.tscn").instantiate()
						#sets the position to the raycasts point of collision
						var collider = raycast_2d.get_collision_point()
						new_pillar.position = collider
						owner.add_child(new_pillar)
					#if you click in the air spawns a box which is smaller and after period of time starts to fall down
					else:
						var box = load("res://scenes/box.tscn").instantiate()
						#sets position to the mouse cursor
						box.position = raycast_2d.position
						owner.add_child(box)
				"water":
					collision_shape_2d.shape.extents.y = player_size / 2
				"fire":
					pass
				"air":
					pass

	move_and_slide()

#simple state change 
func change_state(new_state):
	current_State = new_state


#------
func location(): set_position(current_positon)

func _on_killzone_body_entered(body: Node2D) -> void:
	get_tree().call_group("pillars", "queue_free")
	location()

func _on_checkpoint_body_entered(body: Node2D) -> void: current_positon = position
#-------


func apply_gravity(delta):
	var applied_gravity : float = 0
	
	if current_State == States.CASTING and current_element == "water":
		return
	
	if velocity.y <= max_velocity:
		applied_gravity = gravity_acceleration * delta
		
	if velocity.y < 0 and velocity.y > jump_gravity_max:
		applied_gravity = 0
	
	if abs(velocity.y) < jump_hang_treshold:
		applied_gravity *= jump_hang_gravity_mult
		
	if current_State == States.SLIDING:
		applied_gravity = sliding_grav * delta
		
	velocity.y += applied_gravity



func movement(delta):
	dir = Input.get_axis("left","right")
	#stop if there is no movement input
	if dir == 0:
		velocity.x = Vector2(velocity.x, 0).move_toward(Vector2(0,0), deceleration * delta).x
		return
	# If we are doing movement inputs and above max speed, don't accelerate nor decelerate
	# Except if we are turning
	# (This keeps our momentum gained from outside or slopes)
	if abs(velocity.x) >= speed and sign(velocity.x) == dir:
		return
	# Deciding between acceleration and turn_acceleration
	var accel_rate : float = acceleration if sign(velocity.x) == dir else turning_acceleration
	# Accelerate
	velocity.x += dir * accel_rate * delta
	#change face direction based on input direction
	set_direction(dir)


func set_direction(hor_direction) -> void:
	#if we are not moving dont change face direction
	if hor_direction == 0:
		return
	#flips the player on scale property
	apply_scale(Vector2(hor_direction * face_dir, 1))
	#remembers face direction
	face_dir = hor_direction


func _on_jumping() -> void:
	velocity.y += -jump_force
	
func _on_dashing() -> void:
	if is_on_floor():
		var height = position.y - 300
		var length = position.x + 200 * face_dir
		var duration: float = 0.3
		var water_tween := create_tween()
		water_tween.set_parallel()
		water_tween.tween_property(self,"position:y", height, duration)
		water_tween.tween_property(self, "position:x", length, duration)
	end_dashing.start(2)

func _on_end_dashing_timeout() -> void:
	speed = normal_speed
	collision_shape_2d.shape.extents.y = player_size
	if velocity.x == 0:
		change_state(States.IDLE)
	if is_on_floor() and velocity.x != 0:
		change_state(States.RUN)
	if !is_on_wall() and !is_on_floor():
		change_state(States.AIR)

func change_element() -> void:
	#element that is currently active
	current_element = elements[element_index]
	#on button press change element to next one if we are at the end return back to first one
	if Input.is_action_just_pressed("change element"):
		element_index += 1
		if element_index >= 4:
			element_index = 0


func _on_animations_animation_finished() -> void:
	if %animations.animation == "abillity":
		if velocity.x == 0:
			change_state(States.IDLE)
		
		if is_on_floor() and velocity.x != 0:
			change_state(States.RUN)
	
		if !is_on_wall() and !is_on_floor():
			change_state(States.AIR)
	else:
		return







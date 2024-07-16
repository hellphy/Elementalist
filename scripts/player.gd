class_name Player extends CharacterBody2D


#signals
signal jumping

#gravity
var gravity_acceleration : float = 3840
var max_velocity = 1000
var sliding_grav = gravity_acceleration * 0.05


#player movement variables
var face_dir = 1
var speed = 600
var max_speed = 1200
var deceleration = 3000
var dir
var acceleration = 2800
var turning_acceleration = 9600


#jump variables
var jump_force : float = 1800
var jump_cut : float = 0.25
var jump_gravity_max : float = 500
var jump_hang_treshold : float = 2.0
var jump_hang_gravity_mult : float = 0.1
var wall_pushback = 1300


@onready var raycast_2d: RayCast2D = $"../Raycast2D"
@onready var animations: AnimatedSprite2D = %animations
@onready var state_label: Label = %StateLabel
@onready var label: Label = %Label
#timers
@onready var cooldown: Timer = %Cooldown
@onready var jump_buffer: Timer = %JumpBuffer
@onready var coyote_timer: Timer = %CoyoteTimer


var elements: Array = ["earth", "water", "fire", "air"]
var element_index = 0
var current_element: String


enum States {IDLE, RUN, AIR, SLIDING, CASTING, FALL}
static var current_State = States.IDLE

var current_positon: Vector2 = Vector2(453,520)

func _physics_process(delta: float) -> void:
	
	state_label.text = str(States.keys()[current_State])
	label.text = str(coyote_timer.time_left)
	change_element()
	movement(delta)
	apply_gravity(delta)
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
				change_state(States.CASTING)


		States.AIR:
			#jump buffer from wall 
			if Input.is_action_just_pressed("jump") and coyote_timer.time_left != 0:
				emit_signal("jumping")
				coyote_timer.stop()
			#if jump is released lower the jump
			if Input.is_action_just_released("jump"):
				velocity.y -= (jump_cut * velocity.y)
				
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
				change_state(States.CASTING)


		States.SLIDING:
			#checks which direction you are holding down
			#and pushes you away from the wall to the opposite direction
			if Input.is_action_just_pressed("jump"):
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
			if !is_on_wall() and !is_on_floor():
				change_state(States.AIR)
			if dir == 0 and is_on_wall_only():
				coyote_timer.start()
				change_state(States.AIR)
			if Input.is_action_just_pressed("abillity") and GlobalTimer.time_left == 0:
				change_state(States.CASTING)


		States.CASTING:

			match current_element:

				"earth":
					velocity.x = 0
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
						return
						
					#if you click in the air spawns a box which is smaller and after period of time starts to fall down
					else:
						var box = preload("res://scenes/box.tscn").instantiate()
						#sets position to the mouse cursor
						box.position = raycast_2d.position
						owner.add_child(box)
						return

				"water":
					pass
					print("water")

				"fire":
					pass
					print("fire")

				"air":
					pass
					print("air")

	move_and_slide()

#simple state change 
func change_state(new_state):
	current_State = new_state

#this is used to change state from casting after animation is finished
func change_states():
	if velocity.x == 0:
		change_state(States.IDLE)
		
	if is_on_floor() and velocity.x != 0:
		change_state(States.RUN)
	
	if !is_on_wall() and !is_on_floor():
		change_state(States.AIR)


#------
func location(): set_position(current_positon)

func _on_killzone_body_entered(body: Node2D) -> void:
	get_tree().call_group("pillars", "queue_free")
	location()

func _on_checkpoint_body_entered(body: Node2D) -> void: current_positon = position
#-------


func apply_gravity(delta):
	var applied_gravity : float = 0
	
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
	if dir == 0:
		velocity.x = Vector2(velocity.x, 0).move_toward(Vector2(0,0), deceleration * delta).x
		return
	
	if abs(velocity.x) >= speed and sign(velocity.x) == dir:
		return
		
	var accel_rate : float = acceleration if sign(velocity.x) == dir else turning_acceleration
	
	velocity.x += dir * accel_rate * delta
	
	set_direction(dir)


func set_direction(hor_direction) -> void:
	if hor_direction == 0:
		return
	apply_scale(Vector2(hor_direction * face_dir, 1))
	face_dir = hor_direction


func _on_jumping() -> void:
	velocity.y += -jump_force


func change_element() -> void:
	current_element = elements[element_index]
	if Input.is_action_just_pressed("change element"):
		element_index += 1
		if element_index >= 4:
			element_index = 0


func _on_animations_animation_finished() -> void:
	if %animations.animation == "abillity":
		change_states()
	else:
		return
	


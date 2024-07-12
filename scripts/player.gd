class_name Player extends CharacterBody2D

#signals
signal jumping



#gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var max_velocity = 1000
var sliding_grav = gravity * 0.3

#player movement variables
var face_dir = 1
var speed = 600
var max_speed = 1200
var deceleration = 3000
var dir
var acceleration = 2800
var turning_acceleration = 9600
var jump := 1300
var wall_pushback = 1300


@onready var animations: AnimatedSprite2D = %animations
@onready var state_label: Label = %StateLabel

@onready var dash: Timer = %dash
@onready var casting: Timer = %casting
@onready var cooldown: Timer = %Cooldown
@onready var jump_buffer: Timer = %JumpBuffer
@onready var coyote_timer: Timer = %CoyoteTimer


var elements: Array = ["earth", "water", "fire", "air"]
var element_index = 0
var current_element: String

enum States {IDLE, RUN, AIR, SLIDING, CASTING, FALL}

@export var current_State = States.IDLE

var current_positon: Vector2 = Vector2(453,520)


func _physics_process(delta: float) -> void:

	state_label.text = str(States.keys()[current_State])
	
	change_element()
	
	movement(delta)
	match current_State:
		
		
		States.IDLE:
			animations.play("idle")
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
			movement(delta)
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
			apply_gravity(delta)
			if Input.is_action_just_pressed("jump") and coyote_timer.time_left != 0:
				emit_signal("jumping")
			if Input.is_action_just_released("jump"):
				velocity.y -= -600
			if velocity.y > 0:
				animations.play("fall")
			if velocity.y < 0:
				animations.play("jump")
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
			if Input.is_action_just_pressed("jump"):
				if dir == 1:
					velocity.y += -jump
					velocity.x += -wall_pushback
				elif dir == -1:
					velocity.y += -jump
					velocity.x += wall_pushback
				else:
					pass
			apply_sliding_gravity(delta)
			if is_on_floor() and velocity.x == 0:
				change_state(States.IDLE)
			if is_on_floor() and velocity.x != 0:
				change_state(States.RUN)
			if !is_on_wall() and !is_on_floor():
				change_state(States.AIR)
			if dir == 0 and is_on_wall_only():
				change_state(States.AIR)
			if Input.is_action_just_pressed("abillity") and GlobalTimer.time_left == 0:
				change_state(States.CASTING)
				
		States.CASTING:
			match current_element:
				"earth":
					velocity.x = 0
					%animations.play("abillity")
					get_tree().call_group("pillars", "queue_free")
					get_tree().call_group("box", "queue_free")
					GlobalTimer.start()
						
					if GlobalRaycast.is_colliding():
						var new_pillar = preload("res://scenes/pillar.tscn").instantiate()
						owner.add_child(new_pillar)
						return
				
					else:
						var box = preload("res://scenes/box.tscn").instantiate()
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


func change_state(new_state):
	current_State = new_state

func change_states():
	if velocity.x == 0:
		change_state(States.IDLE)
		
	if is_on_floor() and velocity.x != 0:
		change_state(States.RUN)
	
	if Input.is_action_pressed("jump"):
		emit_signal("jumping")
		change_state(States.AIR)
	
	if !is_on_wall() and !is_on_floor():
		change_state(States.AIR)



func location(): set_position(current_positon)

func _on_killzone_body_entered(body: Node2D) -> void:
	get_tree().call_group("pillars", "queue_free")
	location()

func _on_checkpoint_body_entered(body: Node2D) -> void: current_positon = position


func apply_gravity(delta):
		velocity.y = minf(max_velocity, velocity.y + gravity * delta)


func apply_sliding_gravity(delta):
	velocity.y = minf(max_velocity, velocity.y + sliding_grav * delta)


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
	velocity.y += -jump


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
	


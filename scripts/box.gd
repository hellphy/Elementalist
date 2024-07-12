class_name Box extends AnimatableBody2D

@onready var timer: Timer = %Timer
@onready var raycasts: RayCast2D = %Raycasts


func _ready() -> void:
	position = get_global_mouse_position()

func _physics_process(delta: float) -> void:
	if timer.time_left == 0:
		self.position.y += 500 * delta
	else:
		return
	if raycasts.is_colliding():
		queue_free()

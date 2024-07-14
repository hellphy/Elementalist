class_name Box extends AnimatableBody2D

@onready var timer: Timer = %Timer
@onready var raycasts: RayCast2D = %Raycasts
@onready var area_2d: Area2D = %Area2D




func _physics_process(delta: float) -> void:
	if timer.time_left == 0:
		self.position.y += 700 * delta
	else:
		return
	if raycasts.is_colliding():
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Player:
		queue_free()


func _on_timer_timeout() -> void:
	area_2d.monitorable = true
	area_2d.monitoring = true

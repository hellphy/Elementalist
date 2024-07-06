extends Marker2D
func _ready() -> void:
	%Timer.wait_time = randf_range(2.0,4.0)
func _on_timer_timeout() -> void:
	var new_ball = preload("res://scenes/ball.tscn").instantiate()
	new_ball.position = position
	owner.add_child(new_ball)

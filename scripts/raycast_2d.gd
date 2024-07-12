extends RayCast2D


func _process(delta: float) -> void:
	if GlobalTimer.time_left == 0:
		position = get_global_mouse_position()
	else:
		return
	

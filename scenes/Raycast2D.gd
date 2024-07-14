class_name MainRaycast extends RayCast2D



func _process(delta: float) -> void:
	if Player.current_State == Player.States.CASTING:
		return
	else:
		position = get_global_mouse_position()


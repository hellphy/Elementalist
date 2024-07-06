extends TextureProgressBar
func _physics_process(delta: float) -> void: value = GlobalTimer.time_left

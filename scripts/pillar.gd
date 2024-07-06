extends StaticBody2D
func _ready() -> void:
	%AnimationPlayer.play("pillar")
	await get_tree().process_frame
	var collider = %RayCast2D.get_collision_point()
	if !collider: return
	else: set_position(collider)

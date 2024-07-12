extends StaticBody2D


@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	animation_player.play("pillar")
	await get_tree().process_frame
	var collider = GlobalRaycast.get_collision_point()
	position = collider

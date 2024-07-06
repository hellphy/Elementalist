extends Area2D
var travel_distance = 0
func _physics_process(delta: float) -> void:
	var direction =Vector2.LEFT
	position += direction * 800 * delta
func _on_body_entered(body: Node2D) -> void:
	queue_free()
	if body.is_in_group("Players"): get_tree().call_group("Players", "location")

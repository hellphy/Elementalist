extends Area2D

const SPEED := 1000
const RANGE := 1500
var travel_distance = 0

func _physics_process(delta: float) -> void:
	position.x += delta * SPEED
	
	
	travel_distance += SPEED * delta
	if travel_distance > RANGE:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	queue_free()
	if body.is_in_group("Players"): get_tree().call_group("Players", "location")

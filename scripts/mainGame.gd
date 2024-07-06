extends Control
@onready var start_game =preload("res://scenes/main.tscn") as PackedScene
func _on_button_pressed() -> void:
	get_tree().call_group("Players", "reset")
	get_tree().change_scene_to_packed(start_game)
func _on_button_2_pressed() -> void: get_tree().quit()

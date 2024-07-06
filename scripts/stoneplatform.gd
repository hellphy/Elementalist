class_name StonePlatform extends AnimatableBody2D
@onready var cur_pos = position.y
func move(delta): self.position.y += 300 * delta
func comeback(delta): self.position.y = move_toward(position.y,cur_pos,400 * delta)


 

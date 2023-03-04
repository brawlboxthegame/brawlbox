extends Node2D


# This solely exists to keep the camera facing in the correct direction when flipped.
# No literally, that's it. Why is it done like this? Because I'm stupid, that's why
func _process(delta):
	global_scale.x = 1

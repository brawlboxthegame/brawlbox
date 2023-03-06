extends Line2D
@export var points_count = 30
var point
@onready var tracked = get_parent()
func _ready():
	var new_root = get_parent().get_parent().get_parent().get_parent().get_parent()
	reparent.call_deferred(get_parent().get_parent().get_parent().get_parent().get_parent())
	self.global_position = Vector2(0,0)

func _physics_process(delta):
	point = tracked.global_position
	add_point(point)
	
	while points.size() > points_count:
		remove_point(0)

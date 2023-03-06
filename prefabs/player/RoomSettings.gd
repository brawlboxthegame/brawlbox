extends Node2D

@export var game_active = true
@export var timer = 0
@export var stocks = 3
# Called when the node enters the scene tree for the first time.
func _ready():
	if get_multiplayer_authority() == 1:
		game_active = false
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if get_multiplayer_authority() != 1:
		update_to_authority()

func update_to_authority():
	var net_settings = get_parent().get_parent().get_node("net-1/RoomSettings")
	game_active = net_settings.game_active
	timer = net_settings.timer

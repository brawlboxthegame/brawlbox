extends Node2D
@onready var net_state = get_node("NetworkState")
@onready var player_root = get_parent()
@export var id: int
var character
var playerobject

var done = false

# Spawns in a character of that player's selected type.
func _process(n):
	if net_state.type == "":
		return
		
	elif not done:
		var type = net_state.type
		var character = load("res://characters/%s/%s.tscn"%[type,type]).instantiate()
		var playerobject = character.get_node("Rigidbody/Player")
		character.set_multiplayer_authority(id)
		playerobject.net_parent = self
		
		character.position = Vector2(0,-100)
		character.name = name.replace("net","player")
		player_root.add_child(character, true)
		done = true
		

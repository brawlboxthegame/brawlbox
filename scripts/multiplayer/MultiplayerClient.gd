extends Node

## Networking code. You probably shouldn't touch this -- for your own sanity. 

func _ready():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players.
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(multiplayer.get_unique_id())
		print_debug("i see players: %s" % multiplayer.get_peers())

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)


	
func add_player(id: int):
	var net = preload("res://prefabs/player/NetworkingPlayer.tscn").instantiate()
	net.id = id
	net.set_multiplayer_authority(id)
	net.name = "net-%s" % id
	
	$Players.add_child(net, true)



func del_player(id: int):
	var net = $Players.get_node_or_null("net-%s" % id)
	var player = $Players.get_node_or_null("player-%s" % id)
	if(net != null): net.queue_free()
	if(player != null): player.queue_free()

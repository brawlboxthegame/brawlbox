extends Button




func _on_pressed():
	var net_settings = get_parent().get_parent().get_parent().get_node("Level/Node2D/Players/net-1/RoomSettings")
	net_settings.game_active = true

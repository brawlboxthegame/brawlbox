extends ItemList
@export var selected = ""
@export var selected_tex : Texture2D
@onready var net_ui = get_parent().get_node("HostJoin")
# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open("res://characters")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif dir.current_is_dir():
			var data = load("res://characters/%s/%s.tscn"%[file,file]).instantiate()
			add_item(data.character_name,data.icon_sprite)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_item_selected(index):
	net_ui.visible = true
	selected = get_item_text(index)
	selected_tex = get_item_icon(index)

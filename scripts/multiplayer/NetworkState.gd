extends Node2D
@onready var name_tag = get_node("Name")
@export var damage = 0
@export var damage_owner : String = ""
@export var i_frames = 0
@export var charge_frames = 0
@export var dash_frames = 0
@export var stun_frames = 0
@export var death_frames = 0
@export var player_position = Vector2(0,0)

@export var flipped = false
@export var grabbed = false
@export var grabbing = false
@export var double_jumped = false
@export var wall_check = false
@export var DIRECTIONAL_ONLY = false

@export var STRONG = false
@export var STRONG_RELEASE = false
@export var ATTACK = false
@export var SPECIAL = false
@export var SPECIAL_RELEASE = false

@export var GRAB = false
@export var GRAB_RELEASE = false
@export var SHIELD = false

@export var DASH = false
@export var UP = false
@export var JUMP = false
@export var DOWN = false
@export var RIGHT = false
@export var LEFT = false
@export var JUST_LEFT = false
@export var JUST_RIGHT = false
@export var saved_charge = 0
@export var type = ""
@export var damage_given = 0
@export var damage_taken = 0
@export var kills = 0
@export var deaths = 0
@export var username = ""
# Color((300.0 - get_net().damage)/100, (200.0 - get_net().damage)/100, (100.0 - get_net().damage)/100)
func update_inputs():
	if not is_multiplayer_authority():
		return

	ATTACK = Input.is_action_just_pressed("attack")
	SPECIAL = Input.is_action_pressed("special")
	SPECIAL_RELEASE = Input.is_action_just_released("special")
	STRONG = Input.is_action_pressed("strong")
	STRONG_RELEASE = Input.is_action_just_released("strong")
	GRAB = Input.is_action_just_pressed("grab")
	GRAB_RELEASE = not Input.is_action_pressed("grab")
	SHIELD = Input.is_action_pressed("shield") 
	UP = Input.is_action_pressed("move_up") or Input.is_action_pressed("directional_up")
	JUMP = Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump")
	DOWN = Input.is_action_pressed("move_down") or Input.is_action_pressed("directional_down")
	RIGHT = Input.is_action_pressed("move_right") or Input.is_action_pressed("directional_right")
	LEFT = Input.is_action_pressed("move_left") or Input.is_action_pressed("directional_left")
	JUST_RIGHT = Input.is_action_just_pressed("move_right")
	JUST_LEFT = Input.is_action_just_pressed("move_left")
	DIRECTIONAL_ONLY = Input.is_action_pressed("directional_up") or Input.is_action_pressed("directional_down") or Input.is_action_pressed("directional_right") or Input.is_action_pressed("directional_left")
func update_position(p):
	if not is_multiplayer_authority():
		return
	var snap = 2
	player_position = Vector2(round(p.x/snap)*snap,p.y)
	
func set_dash_frames(n):
	if not is_multiplayer_authority():
		return
	dash_frames = n
func set_stun_frames(n):
	if not is_multiplayer_authority():
		return
	stun_frames = n
func set_i_frames(n):
	if not is_multiplayer_authority():
		return
	i_frames = n
func cancel_invincibility():
	if not is_multiplayer_authority():
		return
	i_frames = 0
	
func charge():
	if not is_multiplayer_authority():
		return
	if charge_frames == 0:
		saved_charge = 0
	charge_frames += 1
	saved_charge = charge_frames
	
func release_charge():
	
	if is_multiplayer_authority():
		charge_frames = 0
	return saved_charge

func set_damage_owner(d):
	if not is_multiplayer_authority():
		return
	damage_owner = d.get_parent().name

func set_double_jumped(d):
	if not is_multiplayer_authority():
		return
	double_jumped = d

func set_wall_check(w):
	if not is_multiplayer_authority():
		return
	wall_check = w

func set_grabbing(g):
	grabbing = g
	
func set_grabbed(g):
	grabbed = g
	
func add_kill():
	kills += 1
func credit_damage(n):
	damage_given += n
func add_damage(n):
	if not is_multiplayer_authority():
		return
	damage += n
	damage_taken += n
	if(damage > 999): 
		damage = 0
		death_frames = 180
		deaths += 1
		grabbing = false
		grabbed = false
		
		if damage_owner != "" && damage_owner != null:
			get_damage_owner().add_kill()
		damage_owner = ""

func flip():
	flipped = not flipped
func get_damage_owner():
	return get_parent().get_parent().get_node("%s/NetworkState" % damage_owner)
func get_damage_player():
	return get_parent().get_parent().get_node("%s/Rigidbody/Player" % damage_owner.replace("net","player"))
	
# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_multiplayer_authority():
		return
	var ui = get_tree().root.get_node("Multiplayer/UI/Net")
	var net_details = get_tree().root.get_node("Multiplayer/UI/Net")
	var sel = ui.get_node("CharacterEntry/Selector")
	var user = ui.get_node("NameEntry/Name")
	type = sel.get_child(sel.current_tab).name
	username = user.text
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	name_tag.text = username
	position = player_position

	
func update_timers():
	if not is_multiplayer_authority():
		return
	if dash_frames > 0:
		dash_frames -= 1
	if death_frames > 0:
		death_frames -= 1
	if stun_frames > 0:
		stun_frames -= 1
	if i_frames > 0:
		i_frames -= 1
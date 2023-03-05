extends CollisionShape2D
# Children
@onready var anim = get_node("Moves")
@onready var root = get_parent().get_parent()
@onready var players = root.get_parent()

@export var net_parent : Node2D
@onready var ground_check1 = get_node("PlayerPrefabs/Raycasts/GroundRay1")
@onready var ground_check2 = get_node("PlayerPrefabs/Raycasts/GroundRay2")
@onready var front_check = get_node("PlayerPrefabs/Raycasts/ForwardRay")
@onready var grab_check = get_node("PlayerPrefabs/Raycasts/GrabRay")
@onready var move_delta = get_node("PlayerPrefabs/MoveDelta")
@onready @export var grab_offset  = get_node("PlayerPrefabs/GrabPosition")
@onready var camera = get_node("PlayerPrefabs/Camera2D")

@onready var rigidbody = get_parent()

@export var DAMAGED = false
@export var GROUNDED = false

# List of moves that a player can make.
const MOVEMENTS =  ["move_wall_kick","move_dash", "move_airdash","move_jump","move_forward"]

var DASH = false


func net():
	return net_parent.get_node("NetworkState")

func _ready():
	if is_multiplayer_authority():
		camera.enabled = true
		camera.visible = true
	else:
		camera.visible = false


func stun_animation():
	self.modulate = Color(1,int(net().stun_frames) % 2,int(net().stun_frames) % 2)
	net().SHIELD = false
	

func _physics_process(delta):
	net().update_timers()
	if net().death_frames > 1:
		net().credit_kill()
		visible = false
		cancel_grab()
		rigidbody.freeze = true
		return
	elif net().death_frames == 1:
		respawn()
		return
	net().update_position(rigidbody.position)
	net().update_inputs()
	
	update_fixed_animations()
	update_player_state()
	update_movement()

	if not net().stun_frames > 0 and not in_move():
		handle_input()

func respawn():
	visible = true
	rigidbody.freeze = false
	move_delta.position = Vector2(0,0)
	rigidbody.global_position = Vector2(0,-100)
	net().set_stun_frames(0)
	net().update_position(rigidbody.position)
	
func update_scale():
	if net().flipped:
		scale = Vector2(-1,1)
	else:
		scale = Vector2(1,1)
func ground_check():
	return ground_check1.is_colliding() or ground_check2.is_colliding()
	
func update_player_state():
	update_scale()
	rigidbody.position = net().player_position
	DASH = false
	if(net().dash_frames > 0):
		if (not net().flipped and net().JUST_RIGHT) or (net().flipped and net().JUST_LEFT):  # This checks if a dash has been input
			DASH = true
			pass
	net().set_wall_check(front_check.is_colliding())
	if GROUNDED and not ground_check():
		net().set_double_jumped(false)
	GROUNDED = ground_check()
	

func update_fixed_animations():
	if net().charge_frames > 0 and net().SPECIAL or net().STRONG:
		var charge_offset = int(0>sin(pow(1.05,net().charge_frames +randf_range(0,0.05))))
		self.modulate = Color(charge_offset,1,charge_offset)
	elif net().i_frames > 0:
		self.modulate = Color(0.7,0.7,1)
	elif net().stun_frames > 0:
		stun_animation()
	else:
		self.modulate = Color(1,1,1) # Reset color if not stunned.
	

func update_movement():
	if net().grabbed:
		if net().damage_owner != "":
			if net().wall_check or not net().get_damage_player().net().grabbing:
				leave_grab()
			else: 
				rigidbody.global_position = net().get_damage_player().grab_offset.global_position
	else:
		leave_grab()
	if move_delta.position != Vector2(0,0):
		set_movement_velocity(move_delta.position)
	if anim.get_current_animation() == "":
		move_delta.position = Vector2(0,0)
		
func apply_friction():
	pass
		

# Grab functionality.
func try_grab():
	if grab_check.is_colliding():
		var gp = grab_check.get_collider().get_node("Player")
		net().set_grab_child(gp.net())
		gp.grab(net())
		net().set_grabbing(true)
		anim.set_current_animation("misc_grab")
	else:
		anim.set_current_animation("misc_grab_fail")

func grab(damage_owner: Node2D):
	if net().damage_owner != "":
		net().get_damage_player().release_grab() # don't cancel, we'll still be grabbed afterwards
	net().set_damage_owner(damage_owner)
	rigidbody.freeze = true
	net().set_grabbed(true)
	net().set_stun_frames(30)

# This function is to call the leave_grab function on the grabbed player.
func cancel_grab():
	if net().grab_child != "":
		net().get_grab_player().leave_grab()
	else:
		release_grab()
		
func release_grab():
	net().set_grabbing(false)
	net().grab_child = ""
	
func leave_grab():
	if net().damage_owner != "" and net().grabbed:
		rigidbody.freeze = false
		net().get_damage_player().release_grab()
		net().set_grabbed(false)

		
# Move/Animation Utilities
func current_move():
	return anim.get_current_animation()
func in_move():
	return current_move() != ""

func move(act, allowed_moves = MOVEMENTS, grab_continue = false):
	if not in_move() or allowed_moves.find(current_move()) != -1:
		leave_grab()
		if not grab_continue:
			cancel_grab()
		anim.set_current_animation(act)

func handle_input():
	if net().SHIELD:
			net().set_i_frames(3)
			move("misc_shield")
	else:
		net().cancel_invincibility()
		if net().GRAB_START:
			try_grab()
		elif net().grabbing and net().GRAB:
			pass
		elif net().grabbing and net().GRAB_RELEASE:
				cancel_grab()
				if net().UP:
					move("throw_up")
				elif net().DOWN:
					move("throw_down")
				else: 
					move("throw_forward")
		else:
			cancel_grab()
			if net().SPECIAL_RELEASE:
				net().release_charge()
				if net().UP and root.CHARGED_UP_SPECIAL:
					move("special_up")
				elif net().DOWN and root.CHARGED_DOWN_SPECIAL:
					move("special_down")
				elif net().RIGHT or net().LEFT and root.CHARGED_FORWARD_SPECIAL:
					move("special_forward")
				elif root.CHARGED_NEUTRAL_SPECIAL:
					move("special_neutral")
				
					
			elif net().SPECIAL:
				if net().UP and not root.CHARGED_UP_SPECIAL:
					move("special_up")
				elif net().DOWN and not root.CHARGED_DOWN_SPECIAL:
					move("special_down")
				elif (net().RIGHT or net().LEFT) and not root.CHARGED_FORWARD_SPECIAL:
					move("special_forward")
				elif not root.CHARGED_NEUTRAL_SPECIAL:
					move("special_neutral")
				else:
					net().charge()
				
			if net().STRONG_RELEASE:
				net().release_charge()
				if net().UP:
					move("strong_up")
				elif net().DOWN:
					move("strong_down")
				elif net().RIGHT or net().LEFT:
					move("strong_forward")
				else:
					move("strong_neutral")
					
			elif net().STRONG:
				net().charge()
			elif net().ATTACK:
				
				if not GROUNDED:
					if net().UP:
						move("air_up")
					elif net().DOWN:
						move("air_down")
					elif net().RIGHT or net().LEFT:
						move("air_forward")
					else: 
						move("air_neutral")
				else:
					if net().UP:
						move("regular_up")
					elif net().DOWN:
						move("regular_down")
					elif net().RIGHT or net().LEFT:
						move("regular_forward")
					else: 
						move("regular_neutral")
			elif DASH:
					if GROUNDED:
						move("move_dash", MOVEMENTS, true)
						net().set_i_frames(10)
					elif not net().double_jumped:
						net().set_double_jumped(true)
						net().set_i_frames(10)
						
						move("move_airdash", MOVEMENTS, true)
			else:
				if net().wall_check and not GROUNDED and net().LEFT != net().RIGHT:
					if net().JUMP:
						net().flip()
						net().set_double_jumped(false)
						move("move_wall_kick", MOVEMENTS, true)
					else:
						set_relative_velocity(Vector2(0,0))
				elif net().JUMP:
					
					if GROUNDED:
						move("move_jump",["move_forward"], true)
					elif not net().double_jumped:
						net().set_double_jumped(true)
						# Base double jump height is 30 units. Scale in the editor accordingly.
						move("move_jump",["move_forward"], true)
				elif net().DOWN and not GROUNDED:
					move("move_duck")
				elif net().LEFT != net().RIGHT:
					net().set_dash_frames(5)
					if (net().LEFT and not net().flipped) or (net().RIGHT and net().flipped):
						net().flip()
					move("move_forward",["move_forward","move_jump"], true)


	
	
func deal_damage(damage_added, knockback: Vector2, stun_frames, cause, damage_owner):
	const PLAYER_REASONS = ["attack"]
	
	var damage_percent = net().damage / 100.0 + 1
	
	
	if is_multiplayer_authority():
		if knockback.x > 0 or knockback.y > 0:
			leave_grab()
		rigidbody.set_linear_velocity(knockback * damage_percent)
		net().add_damage(damage_added)
		net().set_stun_frames(stun_frames)
	if cause in PLAYER_REASONS:
		net().set_damage_owner(damage_owner)
	
	
	
	if(damage_added > 0):
		DAMAGED = true
		
func set_movement_velocity(velo: Vector2):
	velo *= sqrt(rigidbody.gravity_scale)
	velo *= 1.5
	if not GROUNDED:
		velo.x /= 2
	if current_move() == "move_forward":
		velo.x /= 2
	var a = lerp(rigidbody.get_linear_velocity(),Vector2(sign(scale.x), 1) * velo,0.1)
	a.y = rigidbody.get_linear_velocity().y + velo.y
	rigidbody.set_linear_velocity(a)
	

		

func set_relative_velocity(velo: Vector2):
	velo *= rigidbody.gravity_scale

	rigidbody.set_linear_velocity(Vector2(sign(scale.x), 1) * velo)

func handle_during_move():
	pass



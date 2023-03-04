extends CollisionObject2D

@export_category("Projectiles")
@export_subgroup("Summoner Settings")
@export var summons_projectiles = false
@export var projectile_instance: PackedScene
@export_subgroup("Projectile Settings")
@export var is_projectile = false
@export var projectile_lifespan = 60

@export_category("Knockback Stats")
@export var knockback_power: Vector2
@export var stun_frames: int = 0
@export var damage_player: Node2D

@export_category("Damage Stats")
@export var minimum_damage: int = 0
@export var maximum_damage: int = 0

@export_subgroup("Critical Hits")
@export_range(0,100) var crit_chance: int = 0
@export_range(1.0,10.0) var minimum_crit_multiplier: float = 1.0
@export_range(1.0,10.0) var maximum_crit_multiplier: float = 1.0

@export_category("Charged Attacks")
@export var charged_attack = false
@export var peak_charge_frames = 0
@export var charge_affects_damage = false
@export var charge_affects_knockback = false

@export_subgroup("Projectile Summons")
@export var charge_affects_projectile_velocity = false
@export var charge_affects_projectile_damage = false
@export var charge_affects_projectile_knockback = false



var projectiles_sent = true
var charge_frames = 0
func calculated_charge():
	if charge_frames > peak_charge_frames: return 1.0
	return float(charge_frames) / float(peak_charge_frames)

func _ready():
	if damage_player == null and get_parent().get_parent().get_parent() is Node2D:
		damage_player = get_parent().get_parent().get_parent()
		
func _on_body_entered(body):
	if not summons_projectiles and visible:
		deal_damage(body)
		
func _physics_process(delta):
	
	if summons_projectiles:
		if visible and visible != projectiles_sent:
			
			summon_projectiles()
			projectiles_sent = true
		elif not visible:
			projectiles_sent = false
	if is_projectile:
		projectile_lifespan -= 1
	if projectile_lifespan == 0:
		queue_free()
			
func summon_projectiles():
	if charged_attack:
		charge_frames = damage_player.net().saved_charge
		print_debug(charge_frames)
	for chosen_position in get_children():
		if not chosen_position is CollisionShape2D:
			
			var new: RigidBody2D = projectile_instance.instantiate()
			new.position = chosen_position.position
			var modifier
			if damage_player.net().flipped:
				modifier = Vector2(-1, 1)
			else:
				modifier = Vector2(1, 1)
			new.position *= modifier
			new.scale = modifier
			new.linear_velocity *= modifier
			
			if charge_affects_projectile_velocity:
				new.linear_velocity *= calculated_charge()
			if charge_affects_projectile_damage:
				new.minimum_damage *= calculated_charge()
				new.maximum_damage *= calculated_charge()
			if charge_affects_projectile_knockback:
				new.knockback_power *= calculated_charge()
			new.freeze = false
			new.visible = true
			new.damage_player = self.damage_player
			damage_player.get_parent().add_child(new)
			new.reparent(damage_player.get_parent().get_parent().get_parent())

func deal_damage(body):
	if(damage_player == null or not damage_player.is_ancestor_of(body)):
		if damage_player == null:
			damage_player = self
		if charged_attack:
			charge_frames = damage_player.net().release_charge()
	
		var forward_direction = damage_player.scale
		if body is RigidBody2D and body.get_parent().name.contains("player"):
			var child = (body as RigidBody2D).get_child(0)
			
			if child.net().i_frames > 0:
				return
				
			var calculated_damage = randi_range(minimum_damage, maximum_damage)
			if(randi_range(0,99) < crit_chance):
				calculated_damage *= randi_range(minimum_crit_multiplier, maximum_crit_multiplier)
			
			if damage_player.name.contains("Player"):
				child.deal_damage.call_deferred(calculated_damage, forward_direction * knockback_power, stun_frames, "player", damage_player.net())
				damage_player.net().credit_damage(calculated_damage)
			else:
				child.deal_damage.call_deferred(calculated_damage, forward_direction * knockback_power, stun_frames, "environment", null)
		if is_projectile:
			queue_free.call_deferred()

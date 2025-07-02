class_name Player
extends CharacterBody2D
# Player Script 

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_HEALTH = 100
const RESPAWN_TIME = 3

const BULLET  = preload("res://scenes/game/bullet.tscn")
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var sfx_death: AudioStreamPlayer2D = $sfx_death
@onready var sfx_respawn: AudioStreamPlayer2D = $sfx_respawn
@onready var sfx_shoot_1: AudioStreamPlayer2D = $sfx_shoot1


@onready var game: Game = get_parent()

var health = MAX_HEALTH
var facing_left = false

# For individual control of Host and Client player (separated control )
func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	if !is_multiplayer_authority():
		sprite_2d.modulate = Color.RED
		
	

func _physics_process(delta: float) -> void:
	 
	#Can't Control the player if you don't have the authority
	#So host and client can't control each other characters (host can't control both players)
	if !is_multiplayer_authority():
		return	
		
	$GunContainer.look_at(get_global_mouse_position())
	
	if get_global_mouse_position().x < global_position.x:
		$GunContainer/GunSprite.flip_v = true
	else:
		$GunContainer/GunSprite.flip_v = false
		
	if Input.is_action_just_pressed("shoot"):
		shoot.rpc(multiplayer.get_unique_id())
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		sprite_2d.animation = "jumping"
		
		
	# Animations
	if abs(velocity.x) > 1 and is_on_floor():
		sprite_2d.animation = "running"
		if not $sfx_run .playing:
			$sfx_run.play()
	else:
		sprite_2d.animation = "idle"


	# Sprite & weapon flip
	if velocity.x < 0:
		facing_left = true
	elif velocity.x > 0:
		facing_left = false
	sprite_2d.flip_h = facing_left

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY 
		$sfx_jump.play()
		#playing jump sound only when the jump is pressed while player is on floor
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	var is_left = velocity.x < 0  #(moving toward -ve x axis = left)
	sprite_2d.flip_h = is_left
	
	# Combat

@rpc("call_local")
func shoot(shooter_pid):
	$sfx_shoot1.play()
	var bullet = BULLET.instantiate()
	bullet.set_multiplayer_authority(shooter_pid)
	get_parent().add_child(bullet)
	bullet.transform = $GunContainer/GunSprite/Muzzle.global_transform
		

@rpc("any_peer")
func take_damage(amount):
	health -= amount

	if health <= 0:
		hide()
		set_physics_process(false)
		$sfx_death.play()

		await get_tree().create_timer(RESPAWN_TIME).timeout

		health = MAX_HEALTH
		global_position = game.get_random_spawnpoint()
		show()
		set_physics_process(true)
		$sfx_respawn.play()

		
		

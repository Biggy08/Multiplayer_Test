extends Area2D

var speed = 8000
var dmg = 20  # Damage when bullet hits a player

func _physics_process(delta):
	position += transform.x * speed * delta
	
func _on_body_entered(body: Node2D):
	if !is_multiplayer_authority():
		return

	if body is Player:
		# Tell the player's authority to process damage
		body.take_damage.rpc_id(body.get_multiplayer_authority(), dmg)

	remove_bullet.rpc()


@rpc("call_local")
func remove_bullet():
	queue_free()



	

extends Area2D

var speed = 7000
var dmg = 25
func _physics_process(delta):
	position += transform.x * speed * delta



func _on_body_entered(body: Node2D):
	if !is_multiplayer_authority():
		return
		

	if body is Player:
		body.take_damage.rpc_id(body.get_multiplayer_authority(),dmg)
	
	remove_bullet.rpc()
	
@rpc("call_local")
func remove_bullet():
	queue_free()

extends Node2D

@onready var MarkerLeft = $MarkerLeft
@onready var MarkerRight = $MarkerRight
@onready var Lifetime = $Lifetime

var Activated = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Portals")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if Activated:
		if (body.is_in_group("players") and !body.is_in_group("ExemptPlayers")):
			body.add_to_group("ExemptPlayers")
			for Portal in get_tree().get_nodes_in_group("Portals"):
				if Portal.name != name:
					if body.velocity.x > 0:
						Portal.TeleportToMarker("Right", body)
					else:
						Portal.TeleportToMarker("Left", body)

		if body.is_in_group("Bullets") and !body.is_in_group("ExemptPlayers"):
			body.add_to_group("ExemptPlayers")
			
			for Portal in get_tree().get_nodes_in_group("Portals"):
				if Portal.name != name:
					if body.linear_velocity.x > 0:
						Portal.TeleportToMarker("Right", body)
					else:
						Portal.TeleportToMarker("Left", body)
					body.EmptyTrail()
					
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("ExemptPlayers"):
		body.remove_from_group("ExemptPlayers")


func TeleportToMarker(Marker, Player):
	var TargetPosition
	if Marker == "Left":
		TargetPosition = MarkerLeft.global_position
	elif Marker == "Right":
		TargetPosition = MarkerRight.global_position
	
	if Player is RigidBody2D:
		PhysicsServer2D.body_set_state(
			Player.get_rid(),
			PhysicsServer2D.BODY_STATE_TRANSFORM,
			Transform2D(Player.global_rotation, TargetPosition)
		)
	else:
		Player.global_position = TargetPosition


func _on_lifetime_timeout() -> void:
	queue_free()

extends Node2D

var DashesRemaining = 3
var Secondary = ""
var Knockback = 3000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent().name == "Player1":
		Secondary = "SECONDARY"
	elif get_parent().name == "Player2":
		Secondary = "SECONDARY_2"
	elif get_parent().name == "Player3":
		Secondary = "SECONDARY_3"
	elif get_parent().name == "Player4":
		Secondary = "SECONDARY_4"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed(Secondary):
		get_parent().StartDash()
		DashesRemaining -= 1
	
	if DashesRemaining == 0:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body != get_parent():
		if get_parent().IsDashing:
			body.ApplyKnockback(Knockback, get_parent().Direction)
			get_parent().EndDash()
		

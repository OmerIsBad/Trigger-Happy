extends CharacterBody2D

var ShieldDirection

func _ready() -> void:
	scale.x = ShieldDirection

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ShieldDirection = get_parent().get_parent().Direction
	scale.x = ShieldDirection

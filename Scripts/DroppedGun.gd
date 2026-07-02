extends Node2D

var DeletionTime = 20.0
var ShitHowMuchShouldItMove = -5
var ShitWhatsTheGravity = -1

func _process(delta: float) -> void:
	var GunSprite = $GunSprite
	GunSprite.rotation += 0.1
	
	GunSprite.position.y += ShitHowMuchShouldItMove
	ShitHowMuchShouldItMove -= ShitWhatsTheGravity

func _on_delete_timer_timeout() -> void:
	queue_free()

extends Node2D

@onready var AnimatedSprite = $AnimatedSprite2D

var ExemptPlayers = []
var Puncher
var PunchDirection = 1

var PunchKnockbackX: float = 1000.0
var PunchKnockbackY: float = -500.0
var HitTexts: Array[String] = ["Wham!", "Bam!", "Pow!", "Ouchie!", "Ouch!"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ExemptPlayers.append(Puncher)
	if PunchDirection == -1:
		scale.x = PunchDirection
	
	get_parent().velocity.x = 300 * PunchDirection


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if AnimatedSprite.frame == 4:
		queue_free()
	
	get_parent().velocity.y = 100


var TextAlreadyShown = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and not ExemptPlayers.has(body.name):
		if !body.has_node("SpawnShield"):
			global.CameraShake(15.0, 0.2)

			if not TextAlreadyShown:
				TextAlreadyShown = true
				var text = HitTexts[randi_range(0, HitTexts.size() - 1)]
				get_tree().current_scene.add_child(global.SummonText(text, global_position, -1, -1))

			body.velocity.x = PunchKnockbackX * PunchDirection
			body.velocity.y = PunchKnockbackY

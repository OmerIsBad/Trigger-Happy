extends CharacterBody2D

var ShieldDirection
@onready var EquipSFX: AudioStreamPlayer2D = $EquipSFX

func _ready() -> void:
	EquipSFX.play(0.07)
	EquipSFX.reparent(get_tree().current_scene)
	EquipSFX.finished.connect(EquipSFX.queue_free)
	scale.x = ShieldDirection

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ShieldDirection = get_parent().get_parent().Direction
	scale.x = ShieldDirection

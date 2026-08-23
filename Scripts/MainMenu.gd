extends Control

var PlayerSelectScene = preload("uid://df58qbkqclty2")

func _on_start_button_pressed() -> void:
	var NewScene = PlayerSelectScene.instantiate()
	get_tree().root.add_child(NewScene)
	get_tree().current_scene = NewScene
	queue_free()

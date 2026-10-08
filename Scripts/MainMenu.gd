extends Control

var MapSelectScreen = preload("res://Scenes/map_select_screen.tscn")

func _on_start_button_pressed() -> void:
	var NewScene = MapSelectScreen.instantiate()
	get_tree().root.add_child(NewScene)
	get_tree().current_scene = NewScene
	queue_free()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

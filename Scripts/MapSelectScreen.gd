extends Control

var TutorialScene = preload("uid://dw6qm7wwtw3f1")
var PlayerSelectorScene = preload("res://Scenes/PlayerSelector.tscn")
var GrasslandGullyScene = preload("res://Scenes/Level.tscn")
var HazyHollowsScene = preload("res://Scenes/CaveMap.tscn")

func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_packed(TutorialScene)

func _on_gully_button_pressed() -> void:
	var SelectorScreen = PlayerSelectorScene.instantiate()
	SelectorScreen.Level = GrasslandGullyScene
	var tree = get_tree()
	var OldScene = tree.current_scene
	tree.root.add_child(SelectorScreen)
	tree.current_scene = SelectorScreen
	OldScene.queue_free()


func _on_cave_button_pressed() -> void:
	var SelectorScreen = PlayerSelectorScene.instantiate()
	SelectorScreen.Level = HazyHollowsScene
	var tree = get_tree()
	var OldScene = tree.current_scene
	tree.root.add_child(SelectorScreen)
	tree.current_scene = SelectorScreen
	OldScene.queue_free()

extends Camera2D

var CameraSpeed = 5.0

#Margins - world Y positions the camera will never cross
var TopMargin = -500.0
var BottomMargin = 500.0

#How strongly the camera is pulled toward the center of the map vs the players' average
var CenterPreferenceStrength = 0.4  # 0 = ignore center entirely, 1 = always sit at center
var MapCenter = Vector2(960,540)

func _process(delta: float) -> void:
	var Players = get_tree().get_nodes_in_group("players")
	
	if Players.is_empty():
		return
	
	var AveragePosition = Vector2.ZERO
	for Player in Players:
		AveragePosition += Player.global_position
	AveragePosition /= Players.size()
	
	#Blend between the players' average position and the map's center point
	var TargetPosition = AveragePosition.lerp(MapCenter, CenterPreferenceStrength)
	
	#Clamp so the camera never crosses the top/bottom margins
	TargetPosition.y = clamp(TargetPosition.y, TopMargin, BottomMargin)
	
	global_position = global_position.lerp(TargetPosition, CameraSpeed * delta)

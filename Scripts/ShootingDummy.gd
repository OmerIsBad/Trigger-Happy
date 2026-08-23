extends CharacterBody2D

@onready var TextBox = $TextBox

var ItemCrate = preload("uid://cd8susm6ekdgo")
var WeaponCrate = preload("uid://dgdpgsvupls6h")

var Friction = 25
var ExtremeSpeedFriction = 80
var AirResistance = 15
var UpGravity = 40
var DownGravity = 60
var TopSpeed = 500.0
var LastShot

var Student

func _ready() -> void:
	add_to_group("ShootingDummys")
	if Student == "Player1":
		TextBox.add_theme_color_override("font_outline_color", Color("b51111"))
		TextBox.text = "\nPress X To Shoot\nShoot The Dummy Off The Map"
	if Student == "Player2":
		TextBox.add_theme_color_override("font_outline_color", Color("115bb5"))
		TextBox.text = "\nPress 0 To Shoot\nShoot The Dummy Off The Map"
	if Student == "Player3":
		TextBox.add_theme_color_override("font_outline_color", Color("33af22"))
		TextBox.text = "\nPress O To Shoot\nShoot The Dummy Off The Map"
	if Student == "Player4":
		TextBox.add_theme_color_override("font_outline_color", Color("ffdb00"))
		TextBox.text = "\nPress PgUp To Shoot\nShoot The Dummy Off The Map"

func _physics_process(delta: float) -> void:
	#Apply Friction or Air Resistance to bleed off knockback
	if is_on_floor():
		var FrictionToUse = Friction
		if abs(velocity.x) > TopSpeed:
			FrictionToUse = ExtremeSpeedFriction
		
		if abs(velocity.x) < FrictionToUse:
			velocity.x = 0
		elif velocity.x > 0.0:
			velocity.x -= FrictionToUse
		elif velocity.x < 0.0:
			velocity.x += FrictionToUse
	else:
		if abs(velocity.x) < AirResistance:
			velocity.x = 0
		elif velocity.x > 0.0:
			velocity.x -= AirResistance
		elif velocity.x < 0.0:
			velocity.x += AirResistance
	
	#Upwards and downwards gravity
	if velocity.y > 0 and !is_on_floor():
		velocity.y += DownGravity
	else:
		velocity.y += UpGravity
	
	move_and_slide()
	if position.y > 1120:
		var PositionNodeNames = {
			"Player1": "PositionNode",
			"Player2": "PositionNode2",
			"Player3": "PositionNode3",
			"Player4": "PositionNode4",
		}
		
		var NewWeaponBox = WeaponCrate.instantiate()
		if PositionNodeNames.has(Student):
			NewWeaponBox.global_position = get_parent().get_node(PositionNodeNames[Student]).global_position + Vector2(-300, 21)
			NewWeaponBox.Student = Student
		get_tree().current_scene.add_child(NewWeaponBox)

		var NewItemBox = ItemCrate.instantiate()
		if PositionNodeNames.has(Student):
			NewItemBox.global_position = get_parent().get_node(PositionNodeNames[Student]).global_position + Vector2(300, 21)
			NewItemBox.Student = Student
		get_tree().current_scene.add_child(NewItemBox)
		
		queue_free()


func ApplyKnockback(Knockback, PushDirection):
	velocity.x += Knockback * PushDirection

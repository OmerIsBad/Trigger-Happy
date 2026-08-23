extends CharacterBody2D

var ShootingDummy = preload("uid://dkw1sc5lugk8p")

@onready var TextBox = $TextBox

var Friction = 25
var ExtremeSpeedFriction = 80
var AirResistance = 15
var UpGravity = 40
var DownGravity = 60
var TopSpeed = 500.0

var Student

func _ready() -> void:
	add_to_group("Dumm-E")
	if Student == "Player1":
		TextBox.add_theme_color_override("font_outline_color", Color("b51111"))
		TextBox.text = "\nPress C To Punch\nPunch The Dummy Off The Map"
	if Student == "Player2":
		TextBox.add_theme_color_override("font_outline_color", Color("115bb5"))
		TextBox.text = "\nPress . To Punch\nPunch The Dummy Off The Map"
	if Student == "Player3":
		TextBox.add_theme_color_override("font_outline_color", Color("33af22"))
		TextBox.text = "\nPress P To Punch\nPunch The Dummy Off The Map"
	if Student == "Player4":
		TextBox.add_theme_color_override("font_outline_color", Color("ffdb00"))
		TextBox.text = "\nPress PgDn To Punch\nPunch The Dummy Off The Map"

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
		var NewDummy = ShootingDummy.instantiate()
		
		var PositionNodeNames = {
			"Player1": "PositionNode",
			"Player2": "PositionNode2",
			"Player3": "PositionNode3",
			"Player4": "PositionNode4",
		}
		
		if PositionNodeNames.has(Student):
			NewDummy.global_position = get_parent().get_node(PositionNodeNames[Student]).global_position
			NewDummy.Student = Student
		
		get_tree().current_scene.add_child(NewDummy)
		
		queue_free()

func ApplyKnockback(Knockback, PushDirection):
	velocity.x += Knockback * PushDirection

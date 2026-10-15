extends Node
#This code is fucking insane. 
#This is the single longest and most complex piece of code ive ever written

enum State { Idle, Chase, Fight, UseItem, Recover }

@export_group("Difficulty")
@export var ThinkInterval := 0.2
@export_range(0.0, 1.0) var ThinkJitter := 0.25
@export_range(0.0, 1.0) var MissChance := 0.0
@export var ShootYTolerance := 120.0

@export_group("Combat")
@export var ShootRange := 700.0
@export var StopDistance := 150.0
@export var PunchRange := 90.0

@export_group("Navigation")
@export_flags_2d_physics var GroundMask := 1
@export var LedgeLookahead := 60.0
@export var LeapGaps := true
@export var JumpTriggerDx := 400.0
@export var RecoverRayDepth := 600.0

@export_group("Crate Seeking")
@export var CrateSeekRange := 900.0
@export var CrateStopDistance := 30.0
@export var CratePriority := 0.8

@export_group("OSL Strategy")
@export var OslClusterRadius := 280.0
@export var OslAimSpeed := 350.0
@export var OslAimTolerance := 60.0
@export var OslMinAimTime := 0.9
@export var OslMaxAimTime := 2.2
@export var OslTargetJitter := 55.0
@export_range(0.0, 1.0) var OslMissChance := 0.2
@export var OslCooldown := 4.0

@export_group("Jetpack Strategy")
@export var JetpackChaseBurst := 0.4
@export var JetpackRecoveryBurst := 0.7
@export var JetpackCooldown := 1.8
@export var JetpackTargetHeight := 300.0
@export var JetpackRisingSpeedThreshold := -100.0
@export var JetpackDangerMargin := 350.0

@export var DebugPrint := false

const ItemNodes := [
	"MinePlacerItem",
	"ShieldManager",
	"PortalManager",
	"DuckBombManager",
	"JetPack",
	"GrenadeManager",
	"TurretManager",
	"DashManager",
	"OSL"
]

const PlaceRange := {
	"MinePlacerItem": 350.0,
	"DuckBombManager": 350.0,
	"PortalManager": 500.0,
	"TurretManager": 600.0,
}

const OslImmunityGroup := \
	"PlayersThatEitherShotOrAreHitByTheLaserTypeShi"

@onready var Body: CharacterBody2D = get_parent()

var BrainState: State = State.Idle
var ThinkTimer := 0.0
var ItemCooldown := 0.0

var PulseRelease: Array[String] = []
var ReleasedNow: Array[String] = []

var MoveDir := 0.0
var AllowLeap := false
var Recovering := false
var SecondaryHeld := false

var Charging := false
var ChargeStartMs := 0
var ChargeGoalMs := 0
var AimStartMs := 0

# OSL aiming state.
var OslStartedMs := 0
var OslTargetX := 0.0
var OslJitterX := 0.0
var OslMissOffset := 0.0
var OslControlActive := false
var OslPreviousCanMove := true

# Jetpack bursts are time-limited because Secondary is a hold-to-use input.
var JetpackActive := false
var JetpackBurstEndMs := 0
var JetpackNextAllowedMs := 0


func _ready() -> void:
	# Run before the player each physics frame so input pulses are seen.
	process_physics_priority = -1


func _physics_process(Delta: float) -> void:
	# Release last tick's one-frame inputs.
	ReleasedNow.clear()

	for Action in PulseRelease:
		Input.action_release(Action)
		ReleasedNow.append(Action)

	PulseRelease.clear()

	if not is_instance_valid(Body) or not Body.is_in_group("players"):
		ReleaseAll()
		return

	ItemCooldown = maxf(0.0, ItemCooldown - Delta)

	# Keep jetpack use in short bursts and release it automatically.
	TickJetpack()

	# Recovery overrides normal decisions.
	if Recover():
		return

	# Make decisions periodically.
	ThinkTimer -= Delta

	if ThinkTimer <= 0.0:
		ThinkTimer = ThinkInterval * (
			1.0 + randf_range(-ThinkJitter, ThinkJitter)
		)
		Think()

	# OSL aiming must update every frame.
	TickOsl(Delta)

	# Normal movement and grenade charging.
	ApplyMovement()
	TickCharge()


# ----------------------------------------------------------------
# Decisions

func Think() -> void:
	var Target := NearestEnemy()
	var Crate := NearestCrate()

	# Seek a crate when it is worthwhile to do so.
	if Crate != null:
		var CrateDistance := Body.global_position.distance_to(
			Crate.global_position
		)

		if CrateDistance <= CrateSeekRange:
			var ShouldSeekCrate := Target == null

			if Target != null:
				var EnemyOffset: Vector2 = (
					Target.global_position - Body.global_position
				)

				var EnemyScore := (
					absf(EnemyOffset.x)
					+ absf(EnemyOffset.y) * 2.0
				)

				var CrateOffset: Vector2 = (
					Crate.global_position - Body.global_position
				)

				var CrateScore := (
					absf(CrateOffset.x)
					+ absf(CrateOffset.y) * 2.0
				)

				var EnemyInCombatRange := (
					absf(EnemyOffset.x) < ShootRange
					and absf(EnemyOffset.y) < ShootYTolerance
				)

				ShouldSeekCrate = (
					not EnemyInCombatRange
					and CrateScore < EnemyScore * CratePriority
				)

			if ShouldSeekCrate:
				SeekCrate(Crate)
				return

	if Target == null:
		SetState(State.Idle)
		MoveDir = 0.0
		AllowLeap = false
		ReleaseCombat()
		return

	var ToTarget: Vector2 = (
		Target.global_position - Body.global_position
	)

	var Dir := signf(ToTarget.x)
	var Facing: bool = signf(Body.Direction) == Dir
	var InLine := absf(ToTarget.y) < ShootYTolerance
	var InRange := absf(ToTarget.x) < ShootRange

	# Move toward the enemy.
	var WantMove := (
		absf(ToTarget.x) > StopDistance or not Facing
	)

	MoveDir = Dir if WantMove else 0.0
	AllowLeap = LeapGaps and ToTarget.y < ShootYTolerance

	# Jump or drop to get level with the enemy.
	if Body.is_on_floor():
		var WallBlock: bool = Body.is_on_wall() and WantMove
		var TargetAbove := ToTarget.y < -ShootYTolerance

		if WallBlock or (
			TargetAbove
			and absf(ToTarget.x) < JumpTriggerDx
		):
			Pulse(Body.MoveJump)

		elif ToTarget.y > ShootYTolerance:
			Pulse(Body.MoveDown)

	elif (
		ToTarget.y < -ShootYTolerance
		and Body.velocity.y > 0.0
		and Body.CanDoubleJump
		and not Body.CanJump
	):
		Pulse(Body.MoveJump)

	# Shoot only when facing, level enough, and in range.
	var Fire := (
		Facing
		and InLine
		and InRange
		and randf() >= MissChance
	)

	Hold(ShootAction(), Fire)

	# Use items or punch.
	UseItem(ToTarget, InLine, Facing)

	if HasItem():
		SetState(State.UseItem)
	elif InLine and InRange:
		SetState(State.Fight)
	else:
		SetState(State.Chase)


# ----------------------------------------------------------------
# Crate seeking

func NearestCrate() -> Node2D:
	var Best: Node2D = null
	var BestScore := INF

	for GroupName in ["ItemCrates", "WeaponCrates"]:
		for Crate in get_tree().get_nodes_in_group(GroupName):
			if not is_instance_valid(Crate):
				continue

			if not Crate is Node2D:
				continue

			var Offset: Vector2 = (
				Crate.global_position - Body.global_position
			)

			# Prefer crates on roughly the same platform.
			var Score := absf(Offset.x) + absf(Offset.y) * 2.0

			if Score < BestScore:
				BestScore = Score
				Best = Crate

	return Best


func SeekCrate(Crate: Node2D) -> void:
	var ToCrate: Vector2 = (
		Crate.global_position - Body.global_position
	)

	# Walk toward the crate.
	if absf(ToCrate.x) > CrateStopDistance:
		MoveDir = signf(ToCrate.x)
	else:
		MoveDir = 0.0

	AllowLeap = (
		LeapGaps and ToCrate.y < ShootYTolerance
	)

	# Jump toward higher crates or drop toward lower crates.
	if Body.is_on_floor():
		var WallBlock: bool = (
			Body.is_on_wall() and MoveDir != 0.0
		)

		var CrateAbove := ToCrate.y < -ShootYTolerance

		if WallBlock or (
			CrateAbove
			and absf(ToCrate.x) < JumpTriggerDx
		):
			Pulse(Body.MoveJump)

		elif ToCrate.y > ShootYTolerance:
			Pulse(Body.MoveDown)

	# Double jump toward a higher crate when descending.
	elif (
		ToCrate.y < -ShootYTolerance
		and Body.velocity.y > 0.0
		and Body.CanDoubleJump
		and not Body.CanJump
	):
		Pulse(Body.MoveJump)

	ReleaseCombat()
	SetState(State.Chase)


# ----------------------------------------------------------------
# Item usage

func UseItem(
	ToT: Vector2,
	InLine: bool,
	Facing: bool
) -> void:
	var Sec: String = Body.Secondary
	var Dist := ToT.length()
	var NearLevel := (
		absf(ToT.y) < ShootYTolerance * 1.5
	)

	if Body.has_node("OSL"):
		UseOsl(Sec)
		return

	if not HasItem():
		HoldSecondary(false)

		if Facing and Dist < PunchRange and Body.CanPunch:
			Pulse(Sec)

		return

	if Body.has_node("ShieldManager"):
		HoldSecondary(InLine and Dist < ShootRange)

	elif Body.has_node("JetPack"):
		ConsiderJetpack(ToT)

	elif Body.has_node("GrenadeManager"):
		StartGrenade(ToT, Facing)

	elif Body.has_node("DashManager"):
		var Left: int = (
			Body.get_node("DashManager").DashesRemaining
		)

		if (
			Left > 0
			and ItemCooldown <= 0.0
			and Facing
			and Dist > 300.0
			and Dist < 800.0
		):
			Pulse(Sec)
			ItemCooldown = 0.6

	elif ItemCooldown <= 0.0:
		for ItemName in PlaceRange:
			if (
				Body.has_node(ItemName)
				and NearLevel
				and Dist < PlaceRange[ItemName]
			):
				Pulse(Sec)
				ItemCooldown = 1.5
				break


func UseOsl(Sec: String) -> void:
	var Osl = Body.get_node("OSL")
	var OslState = Osl.CurrentState

	# Start a new aiming attempt when the OSL is off.
	if OslState == "Off":
		if ItemCooldown > 0.0:
			return

		var NewTargetX := BestOslTargetX()

		if is_inf(NewTargetX):
			return

		OslStartedMs = Time.get_ticks_msec()
		OslTargetX = NewTargetX

		# Small error so the bot isn't perfectly accurate.
		OslJitterX = randf_range(
			-OslTargetJitter,
			OslTargetJitter
		)

		OslMissOffset = 0.0

		# Occasionally choose a less accurate aim point.
		if randf() < OslMissChance:
			OslMissOffset = randf_range(-220.0, 220.0)

		Pulse(Sec)


func BestOslTargetX() -> float:
	var Targets: Array[Node2D] = []

	for Entry in get_tree().get_nodes_in_group("players"):
		if not is_instance_valid(Entry):
			continue

		if not Entry is Node2D or Entry == Body:
			continue

		# Ignore players already protected by the OSL's own immunity.
		if Entry.is_in_group(OslImmunityGroup):
			continue

		Targets.append(Entry)

	if Targets.is_empty():
		return INF

	var Osl: Node2D = Body.get_node("OSL")
	var BestX: float = Targets[0].global_position.x
	var BestCount := 0
	var BestDistance := INF

	# Treat each player's horizontal position as a possible cluster center.
	for Candidate in Targets:
		var CandidateX: float = Candidate.global_position.x
		var TotalX := 0.0
		var Count := 0

		for Other in Targets:
			if absf(Other.global_position.x - CandidateX) <= OslClusterRadius:
				TotalX += Other.global_position.x
				Count += 1

		if Count == 0:
			continue

		var CenterX := TotalX / Count
		var DistanceToOsl := absf(
			CenterX - Osl.global_position.x
		)

		if (
			Count > BestCount
			or (
				Count == BestCount
				and DistanceToOsl < BestDistance
			)
		):
			BestCount = Count
			BestX = CenterX
			BestDistance = DistanceToOsl

	return BestX


func TickOsl(Delta: float) -> void:
	# The OSL may have been consumed or removed.
	if not Body.has_node("OSL"):
		if OslControlActive:
			Body.CanMove = OslPreviousCanMove
			OslControlActive = false
			OslStartedMs = 0

			Hold(Body.MoveLeft, false)
			Hold(Body.MoveRight, false)

		return

	var Osl: Node2D = Body.get_node("OSL")
	var OslState = Osl.CurrentState

	# Don't clear the timer while the activation input is pending.
	if OslState == "Off":
		return

	# Lock the player in place while controlling the laser.
	if not OslControlActive:
		OslPreviousCanMove = Body.CanMove
		OslControlActive = true

	Body.CanMove = false
	MoveDir = 0.0
	AllowLeap = false

	Hold(ShootAction(), false)

	# Once warning starts, stop steering and let the laser fire.
	if OslState == "Warning" or OslState == "Shooting":
		Hold(Body.MoveLeft, false)
		Hold(Body.MoveRight, false)
		return

	if OslState != "Aiming":
		return

	# Refresh the cluster target as players move.
	var NewTargetX := BestOslTargetX()

	if not is_inf(NewTargetX):
		OslTargetX = NewTargetX

	var DesiredX := (
		OslTargetX
		+ OslJitterX
		+ OslMissOffset
	)

	var AimError := DesiredX - Osl.global_position.x

	Hold(Body.MoveLeft, AimError < -OslAimTolerance)
	Hold(Body.MoveRight, AimError > OslAimTolerance)

	var Elapsed := (
		Time.get_ticks_msec() - OslStartedMs
	) / 1000.0

	var Aligned := absf(AimError) <= OslAimTolerance

	# Fire after enough aiming time if aligned, or commit at the
	# maximum time so the bot doesn't track a player forever
	if (
		Elapsed >= OslMinAimTime
		and (
			Aligned
			or Elapsed >= OslMaxAimTime
		)
	):
		Hold(Body.MoveLeft, false)
		Hold(Body.MoveRight, false)

		Pulse(Body.Secondary)
		ItemCooldown = OslCooldown


func StartGrenade(ToT: Vector2, Facing: bool) -> void:
	if Charging or ItemCooldown > 0.0:
		return

	var Dist := ToT.length()

	if (
		Facing
		and Dist < 900.0
		and absf(ToT.y) < 250.0
	):
		Charging = true
		ChargeStartMs = Time.get_ticks_msec()

		# Farther targets get a longer charge.
		ChargeGoalMs = int(
			lerpf(
				200.0,
				900.0,
				clampf(Dist / 900.0, 0.0, 1.0)
			)
		)

		HoldSecondary(true)


# ----------------------------------------------------------------
# Jetpack strategy

func ConsiderJetpack(ToTarget: Vector2) -> void:
	# Prefer ordinary jumping while grounded.
	if Body.is_on_floor():
		return

	# Only boost when the target is meaningfully above us.
	if ToTarget.y > -JetpackTargetHeight:
		return

	# If already rising quickly, save the jetpack for later.
	if Body.velocity.y < JetpackRisingSpeedThreshold:
		return

	# Avoid spending fuel on very distant horizontal targets.
	if absf(ToTarget.x) > ShootRange * 1.25:
		return

	RequestJetpack(JetpackChaseBurst)


func RequestJetpack(BurstDuration: float) -> void:
	if not Body.has_node("JetPack"):
		return

	var Now := Time.get_ticks_msec()

	if JetpackActive or Now < JetpackNextAllowedMs:
		return

	JetpackActive = true
	JetpackBurstEndMs = Now + int(BurstDuration * 1000.0)
	JetpackNextAllowedMs = Now + int(
		(BurstDuration + JetpackCooldown) * 1000.0
	)
	HoldSecondary(true)


func TickJetpack() -> void:
	if not JetpackActive:
		return

	var Now := Time.get_ticks_msec()

	if (
		not Body.has_node("JetPack")
		or Now >= JetpackBurstEndMs
	):
		JetpackActive = false
		HoldSecondary(false)
		return

	# Keep Secondary held only while this burst is active.
	HoldSecondary(true)


# ----------------------------------------------------------------
# Recovery

func Recover() -> bool:
	if Body.is_on_floor():
		Recovering = false
		return false

	if not Recovering:
		var Falling: bool = Body.velocity.y > 0.0

		var NoGround := not GroundAt(
			0.0,
			RecoverRayDepth
		)

		var TooLow: bool = (
			Body.position.y > Body.YBoundary - 600.0
		)

		if Falling and (NoGround or TooLow):
			Recovering = true
		else:
			return false

	SetState(State.Recover)
	Charging = false

	var Home: Vector2 = Body.RespawnPosition
	var Dx := Home.x - Body.position.x
	var Dir := signf(Dx) if absf(Dx) > 40.0 else 0.0

	Hold(Body.MoveLeft, Dir < 0.0)
	Hold(Body.MoveRight, Dir > 0.0)
	Hold(Body.MoveDown, false)
	Hold(ShootAction(), false)

	var HasJetpack: bool = Body.has_node("JetPack")

	if HasJetpack:
		var FallingFast := Body.velocity.y > 50.0
		var DangerouslyLow: bool = (
			Body.position.y > float(Body.YBoundary) - JetpackDangerMargin
		)

		# Save fuel until the bot is falling or close to the boundary.
		if FallingFast or DangerouslyLow:
			RequestJetpack(JetpackRecoveryBurst)
	else:
		HoldSecondary(false)

	if (
		Body.velocity.y > 0.0
		and (Body.CanJump or Body.CanDoubleJump)
	):
		Pulse(Body.MoveJump)

	elif (
		not HasJetpack
		and Body.has_node("DashManager")
		and ItemCooldown <= 0.0
		and Body.get_node("DashManager").DashesRemaining > 0
		and Body.position.y > Home.y + 200.0
	):
		Pulse(Body.MoveJump)
		Pulse(Body.Secondary)
		ItemCooldown = 0.4

	return true


# ----------------------------------------------------------------
# Movement

func ApplyMovement() -> void:
	if not Body.CanMove:
		return

	var Dir := MoveDir

	# Prevent walking off ledges unless a leap is allowed.
	if (
		Dir != 0.0
		and Body.is_on_floor()
		and not GroundAt(
			Dir * LedgeLookahead,
			250.0
		)
	):
		if AllowLeap:
			Pulse(Body.MoveJump)
		else:
			Dir = 0.0

	Hold(Body.MoveLeft, Dir < 0.0)
	Hold(Body.MoveRight, Dir > 0.0)


func TickCharge() -> void:
	if not Charging:
		return

	var Expired := (
		Time.get_ticks_msec() - ChargeStartMs
		>= ChargeGoalMs
	)

	if Expired or not Body.has_node("GrenadeManager"):
		HoldSecondary(false)
		Charging = false
		ItemCooldown = 1.0


# ----------------------------------------------------------------
# Helpers

func NearestEnemy() -> Node2D:
	var Best: Node2D = null
	var BestScore := INF

	var Fallback: Node2D = null
	var FallbackScore := INF

	for Entry in get_tree().get_nodes_in_group("players"):
		if Entry == Body or not is_instance_valid(Entry):
			continue

		var Offset: Vector2 = (
			Entry.global_position - Body.global_position
		)

		# Same platform enemies score closer than distant vertical targets.
		var Score := absf(Offset.x) + absf(Offset.y) * 2.0

		if Score < FallbackScore:
			FallbackScore = Score
			Fallback = Entry

		if (
			Entry.has_node("SpawnShield")
			or Entry.is_in_group("DashInvincible")
		):
			continue

		if Score < BestScore:
			BestScore = Score
			Best = Entry

	return Best if Best != null else Fallback


func GroundAt(OffsetX: float, Depth: float) -> bool:
	var Space := Body.get_world_2d().direct_space_state

	var From: Vector2 = (
		Body.global_position + Vector2(OffsetX, 0.0)
	)

	var Query := PhysicsRayQueryParameters2D.create(
		From,
		From + Vector2(0.0, Depth)
	)

	Query.exclude = [Body.get_rid()]
	Query.collision_mask = GroundMask

	return not Space.intersect_ray(Query).is_empty()


func HasItem() -> bool:
	for ItemName in ItemNodes:
		if Body.has_node(ItemName):
			return true

	return false


func ShootAction() -> String:
	var PlayerNumber := Body.name.trim_prefix("Player")
	return "SHOOT" if PlayerNumber == "1" else "SHOOT_" + PlayerNumber


func SetState(NewState: State) -> void:
	if NewState != BrainState:
		BrainState = NewState

		if DebugPrint:
			print(Body.name, " -> ", State.keys()[NewState])


func Hold(Action: String, Pressed: bool) -> void:
	if Pressed:
		Input.action_press(Action)
	else:
		Input.action_release(Action)


func HoldSecondary(Pressed: bool) -> void:
	SecondaryHeld = Pressed
	Hold(Body.Secondary, Pressed)


func Pulse(Action: String) -> void:
	# Avoid duplicate presses and presses immediately after release.
	if Action in PulseRelease or Action in ReleasedNow:
		return

	Input.action_press(Action)
	PulseRelease.append(Action)


func ReleaseCombat() -> void:
	Hold(ShootAction(), false)
	# Don't cancel a jetpack burst just because combat inputs are released
	if not JetpackActive:
		HoldSecondary(false)
	Charging = false


func ReleaseAll() -> void:
	for Action in [
		Body.MoveLeft,
		Body.MoveRight,
		Body.MoveJump,
		Body.MoveDown,
		Body.Secondary,
		ShootAction()
	]:
		Input.action_release(Action)

	Charging = false
	SecondaryHeld = false


func _exit_tree() -> void:
	if is_instance_valid(Body):
		if OslControlActive:
			Body.CanMove = OslPreviousCanMove

		ReleaseAll()

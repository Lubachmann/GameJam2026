extends Area2D

@export var speed := 50
@export var left_limit := -500   # x-position where NPC turns right
@export var right_limit := 500  # x-position where NPC turns left
@onready var sprite = $AnimatedSprite2D
@onready var excl = $Sprite2D
@onready var rat = get_node("/root/Game/Rat")
@onready var cage = get_node("/root/Game/cage")
@onready var hiding_spot = get_node("/root/Game/FruitBasket")
@onready var hiding_spot2 = get_node("/root/Game/Potatobag")

var velocity := Vector2.ZERO
var moving_left := true  # track direction
var caught_rat := false  # track if we just caught the rat
var catch_timer := 0.0   # timer for catch animation
const CATCH_DURATION = 2.0  # 2 seconds freeze

func _process(delta):
	# Handle catch timer
	if caught_rat:
		catch_timer -= delta
		if catch_timer <= 0:
			# Resume normal behavior after catch
			caught_rat = false
			excl.visible = false
		return  # Don't do anything else while catching
	
	var player_detected := false

	# 1️⃣ Check if NPC collides with player
	for body in get_overlapping_bodies():
		if body == rat:
			# 2️⃣ Check if player is wearing mask AND inside hiding spot
			var in_hiding = hiding_spot.overlaps_body(rat)
			var in_hiding2 = hiding_spot2.overlaps_body(rat)
			if not (rat.mask_equipped and (in_hiding or in_hiding2)):
				player_detected = true
				catch_rat()
			break

	if player_detected:
		# Stop and show exclamation (but don't resume movement yet)
		velocity.x = 0
		sprite.play("idle")
		excl.visible = true
	else:
		# Patrol
		excl.visible = false
		if moving_left:
			velocity.x = -speed
			sprite.flip_h = true
		else:
			velocity.x = speed
			sprite.flip_h = false

		# Check boundaries
		if position.x < left_limit:
			moving_left = false
		elif position.x > right_limit:
			moving_left = true

		sprite.play("walking")

	# Move NPC
	position += velocity * delta

func catch_rat():
	if caught_rat:
		return  # Already caught, don't catch again
	
	caught_rat = true
	catch_timer = CATCH_DURATION
	
	# Freeze the rat for 2 seconds
	rat.set_frozen(true, CATCH_DURATION)
	
	# Teleport rat back to cage
	rat.global_position = cage.global_position + Vector2(0, 20)  # Slightly above cage center
	
	# Unequip mask and drop tissue if carrying
	rat.unequip_mask()
	if rat.carrying_tissue:
		rat.carrying_tissue = false
		rat.tissue.visible = false
	
	print("[Owner] Caught the rat! Returning to cage...")

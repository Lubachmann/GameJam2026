extends Area2D

@export var speed := 50
@export var left_limit := -500   # x-position where NPC turns right
@export var right_limit := 500  # x-position where NPC turns left
@onready var sprite = $AnimatedSprite2D
@onready var excl = $Sprite2D
@onready var rat = get_node("/root/Game/Rat")
@onready var hiding_spot = get_node("/root/Game/FruitBasket")
@onready var hiding_spot2 = get_node("/root/Game/Potatobag")

var velocity := Vector2.ZERO
var moving_left := true  # track direction

func _process(delta):
	var player_detected := false

	# 1️⃣ Check if NPC collides with player
	for body in get_overlapping_bodies():
		if body == rat:
			# 2️⃣ Check if player is wearing mask AND inside hiding spot
			var in_hiding = hiding_spot.overlaps_body(rat)
			var in_hiding2 = hiding_spot2.overlaps_body(rat)
			if not (rat.mask_equipped and (in_hiding or in_hiding2)):
				player_detected = true
			break

	if player_detected:
		# Stop and show exclamation
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

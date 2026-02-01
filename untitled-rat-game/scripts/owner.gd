extends Area2D

# State system
enum OwnerState { MINDING_BUSINESS, THINKING, WALKING, GRABBING, WALKING_AWAY }
var current_state = OwnerState.MINDING_BUSINESS

# Movement
@export var speed := 200
@export var left_limit := -500
@export var right_limit := 500
@export var walk_away_min_distance := 200.0  # Minimum distance to walk away
@export var walk_away_max_distance := 400.0  # Maximum distance to walk away

# Timers
var state_timer := 0.0
var thinking_duration := 6.0  # How long to show thought bubble
var time_before_next_walk := 3.0  # Time minding business before walking
var grab_duration := 1.0  # How long grabbing animation plays
var walk_away_target_distance := 0.0  # Random distance to walk away

# References
@onready var sprite = $AnimatedSprite2D
@onready var excl = $Sprite2D
@onready var thought_bubble = $ThoughtBubble
@onready var thought_icon = $ThoughtBubble/Icon
@onready var rat = get_node("/root/Game/Rat")
@onready var hiding_spot = get_node("/root/Game/FruitBasket")
@onready var hiding_spot2 = get_node("/root/Game/Potatobag")

# Table objects
var fruit_basket = null
var potato_bag = null
var target_object = null  # What the owner wants to grab
var table_objects = []

# Thought bubble icon textures
var apple_texture = preload("res://assets/apple.png")
var potato_texture = preload("res://assets/potato.png")

var velocity := Vector2.ZERO
var moving_left := true

func _ready():
	# Get references to table objects
	fruit_basket = get_node("/root/Game/FruitBasket")
	potato_bag = get_node("/root/Game/Potatobag")
	table_objects = [fruit_basket, potato_bag]
	
	# Start minding business
	current_state = OwnerState.MINDING_BUSINESS
	sprite.play("minding_business")
	thought_bubble.visible = false
	excl.visible = false
	state_timer = time_before_next_walk

func _process(delta):
	var player_detected := false
	
	# Check if player is detected (works in all states)
	for body in get_overlapping_bodies():
		if body == rat:
			var in_hiding = hiding_spot.overlaps_body(rat)
			var in_hiding2 = hiding_spot2.overlaps_body(rat)
			if not (rat.mask_equipped and (in_hiding or in_hiding2)):
				player_detected = true
			break
	
	# If player detected, override state and show exclamation
	if player_detected:
		velocity.x = 0
		sprite.play("idle")
		excl.visible = true
		thought_bubble.visible = false
		position += velocity * delta
		return
	else:
		excl.visible = false
	
	# State machine
	match current_state:
		OwnerState.MINDING_BUSINESS:
			_process_minding_business(delta)
		
		OwnerState.THINKING:
			_process_thinking(delta)
		
		OwnerState.WALKING:
			_process_walking(delta)
		
		OwnerState.GRABBING:
			_process_grabbing(delta)
		
		OwnerState.WALKING_AWAY:
			_process_walking_away(delta)
	
	# Move NPC
	position += velocity * delta

func _process_minding_business(delta):
	velocity.x = 0
	sprite.play("minding_business")
	thought_bubble.visible = false
	
	state_timer -= delta
	if state_timer <= 0:
		# Time to think about getting something
		change_state(OwnerState.THINKING)

func _process_thinking(delta):
	velocity.x = 0
	sprite.play("minding_business")  # Continue minding business animation
	thought_bubble.visible = true  # Overlay thought bubble
	
	state_timer -= delta
	if state_timer <= 0:
		# Done thinking, start walking
		change_state(OwnerState.WALKING)

func _process_walking(delta):
	thought_bubble.visible = false
	
	# Check if we've reached the target object by x-coordinate proximity
	if target_object:
		var distance_to_target = abs(position.x - target_object.global_position.x)
		var reach_threshold = 10.0  # Very small delta (10 pixels)
		
		if distance_to_target <= reach_threshold:
			print("[Owner] Reached target object: %s (distance: %.1f)" % [target_object.name, distance_to_target])
			# Stop and grab the item
			change_state(OwnerState.GRABBING)
			return
	
	# Continue patrol behavior
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

func _process_grabbing(delta):
	velocity.x = 0
	sprite.play("grabbing")
	
	state_timer -= delta
	if state_timer <= 0:
		# Done grabbing, walk away
		change_state(OwnerState.WALKING_AWAY)

func _process_walking_away(delta):
	# Check if we're far enough from the target object
	if target_object:
		var distance_from_target = abs(position.x - target_object.global_position.x)
		
		if distance_from_target >= walk_away_target_distance:
			# Done walking away, return to minding business
			print("[Owner] Walked away %.1f pixels from target" % distance_from_target)
			change_state(OwnerState.MINDING_BUSINESS)
			return
	
	# Walk in the direction we're facing
	if moving_left:
		velocity.x = -speed
		sprite.flip_h = true
	else:
		velocity.x = speed
		sprite.flip_h = false
	
	# Check boundaries (reverse if we hit a wall)
	if position.x < left_limit:
		moving_left = false
	elif position.x > right_limit:
		moving_left = true
	
	sprite.play("walking")

func change_state(new_state: OwnerState):
	current_state = new_state
	
	match new_state:
		OwnerState.MINDING_BUSINESS:
			state_timer = time_before_next_walk
			target_object = null
			print("[Owner] Minding own business for %.1fs" % state_timer)
		
		OwnerState.THINKING:
			state_timer = thinking_duration
			# Pick random object to want
			target_object = table_objects.pick_random()
			# Show corresponding icon in thought bubble
			if target_object == fruit_basket:
				thought_icon.texture = apple_texture
				print("[Owner] Thinking about getting apple...")
			else:
				thought_icon.texture = potato_texture
				print("[Owner] Thinking about getting potato...")
		
		OwnerState.WALKING:
			print("[Owner] Walking to get %s" % target_object.name)
		
		OwnerState.GRABBING:
			state_timer = grab_duration
			velocity.x = 0
			print("[Owner] Grabbing %s" % target_object.name)
		
		OwnerState.WALKING_AWAY:
			# Pick random distance to walk away (with minimum)
			walk_away_target_distance = randf_range(walk_away_min_distance, walk_away_max_distance)
			# Pick random direction to walk away
			moving_left = randf() > 0.5
			print("[Owner] Walking away %.1f pixels in %s direction" % [walk_away_target_distance, "left" if moving_left else "right"])

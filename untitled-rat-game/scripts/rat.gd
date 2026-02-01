extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var mask = $masks
@onready var hand = $hand
@onready var tissue = $hand/tissue
@onready var pickup_area = $PickupArea
@onready var transf = $transform
var apple_texture = preload("res://assets/apple.png")
var potato_texture = preload("res://assets/potato.png")
@onready var tissue_box = get_node("/root/Game/Tissuebox")
@onready var cage = get_node("/root/Game/cage")
@onready var fruitbasket = get_node("/root/Game/FruitBasket")
@onready var potatobag = get_node("/root/Game/Potatobag")
var mask_equipped := false  # true when mask is on
var carrying_tissue := false
var amount_tissues := 0
var is_frozen := false  # New: track if rat is frozen by owner
var freeze_timer := 0.0  # New: timer for unfreezing

func equip_mask():
	for area in pickup_area.get_overlapping_areas():
		if fruitbasket == area:
			transf.texture = apple_texture
			transf.visible = true
		if potatobag == area:
			transf.texture = potato_texture
			transf.visible = true
		
		mask.visible = true
		mask_equipped = true
	
func unequip_mask():
	mask.visible = false
	mask_equipped = false
	transf.visible = false

# New: Function to freeze/unfreeze the rat
func set_frozen(frozen: bool, duration: float = 2.0):
	is_frozen = frozen
	if frozen:
		freeze_timer = duration
		velocity = Vector2.ZERO  # Stop all movement
		animated_sprite.play("idle")
		mask.play("idle")
	else:
		freeze_timer = 0.0


func _physics_process(delta):
	# Handle freeze timer
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0:
			is_frozen = false
		else:
			# Don't process any input while frozen
			velocity.y += get_gravity().y * delta  # Still apply gravity
			move_and_slide()
			return
	
	if Input.is_action_just_pressed("grab_tissue") and not carrying_tissue:

		for area in pickup_area.get_overlapping_areas():
			
			if tissue_box == area: #area.is_in_group("Tissuebox"):
				carrying_tissue = true
				tissue.visible = true
				break
				
	if Input.is_action_just_pressed("grab_tissue") and carrying_tissue:
		for area in pickup_area.get_overlapping_areas():
			if cage == area:
				carrying_tissue = false
				tissue.visible = false
				cage.tissue_count += 1
				print(amount_tissues)
				break
			
		


	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.

		
	if Input.is_action_just_pressed("startQTE"):
		QTESystem.start_mask_qte(self)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction:
		velocity.x = direction * SPEED
		animated_sprite.play("walking")
		unequip_mask()
		mask.play("walk")

		var facing_left := direction < 0

		animated_sprite.flip_h = facing_left
		mask.flip_h = facing_left

	# Flip hand correctly
		if facing_left:
			hand.scale.x = -1
		else:
			hand.scale.x = 1
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("idle")
		mask.play("idle")
	move_and_slide()

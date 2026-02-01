extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var mask = $masks
@onready var hand = $hand
@onready var tissue = $hand/tissue
@onready var pickup_area = $PickupArea
@onready var tissue_box = get_node("/root/Game/Tissuebox")
@onready var cage = get_node("/root/Game/cage")
var mask_equipped := false  # true when mask is on
var carrying_tissue := false
var amount_tissues := 0


func equip_mask():
	mask.visible = true
	mask_equipped = true
	
func unequip_mask():
	mask.visible = false
	mask_equipped = false



func _physics_process(delta):
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
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("up"):
		QTESystem.start_mask_qte(self)

	if Input.is_action_just_pressed("down"):
		unequip_mask()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction:
		velocity.x = direction * SPEED
		animated_sprite.play("walking")
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

extends CanvasLayer

signal minigame_finished
signal minigame_failed # Added for more gameplay depth

@export_range(5, 100) var number_actions : int = 10
@export_range(2, 5) var number_actions_shown : int = 5

# Using your existing assets
var atlas = preload("res://assets/arrow-keys.png")
const ATLAS_COORDS = {
	'up': Rect2i(0, 0, 16, 16),
	'left': Rect2i(32, 0, 16, 16),
	'right': Rect2i(64, 0, 16, 16),
	'down': Rect2i(96, 0, 16, 16)
}

var actions = ATLAS_COORDS.keys()
var action_queue = []

@onready var button_box : HBoxContainer = %ButtonBox

func _ready() -> void:
	# Initialize the full sequence
	for i in range(number_actions):
		action_queue.push_back(actions.pick_random())
	
	# Initial UI Fill
	_update_display()

func create_action_node(action: String) -> TextureRect:
	var node = TextureRect.new()
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = atlas
	atlas_texture.region = ATLAS_COORDS[action]
	node.texture = atlas_texture
	# Good for visibility on different backgrounds
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
	return node

func _unhandled_input(event: InputEvent) -> void:
	if action_queue.is_empty():
		return

	# Check if the event is one of our defined actions
	for action in actions:
		if event.is_action_pressed(action):
			_handle_attempt(action)

func _handle_attempt(pressed_action: String) -> void:
	if pressed_action == action_queue.front():
		# Success! Remove the top item
		action_queue.pop_front()
		
		# Update UI: Remove first child
		if button_box.get_child_count() > 0:
			var old_node = button_box.get_child(0)
			old_node.queue_free()
		
		# Add next item in line to the end of the visible box
		if action_queue.size() >= number_actions_shown:
			var new_action = action_queue[number_actions_shown - 1]
			button_box.add_child(create_action_node(new_action))
			
		if action_queue.is_empty():
			minigame_finished.emit()
	else:
		# Optional: Handle wrong key press
		print("Wrong key!") 
		# You could emit minigame_failed here or shake the screen

func _update_display() -> void:
	# Clears box and shows current window of actions
	for child in button_box.get_children():
		child.queue_free()
		
	var display_count = min(number_actions_shown, action_queue.size())
	for i in range(display_count):
		button_box.add_child(create_action_node(action_queue[i]))

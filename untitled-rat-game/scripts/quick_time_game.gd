extends CanvasLayer

signal minigame_finished

@export_range(5, 100) var number_actions : int = 10
@export_range(2, 5) var number_actions_shown : int = 5

var action_scene = preload("res://scenes/QuickTimeEventButton.tscn")
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(number_actions):
		action_queue.push_back(actions.pick_random())
		
	for i in range(number_actions_shown):
		var action = action_queue[i]
		var node = create_action_node(action)
		button_box.add_child(node)
		
func create_action_node(action: String) -> TextureRect:
	var node = TextureRect.new()
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = atlas
	atlas_texture.region = ATLAS_COORDS[action]
	node.texture = atlas_texture
	return node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if len(action_queue) > 0 and Input.is_action_just_pressed(action_queue.front()):
		var old_node = button_box.get_child(0)
		button_box.remove_child(old_node)
		old_node.queue_free()
		action_queue.pop_front()

		if len(action_queue) >= number_actions_shown:
			var new_action = action_queue[number_actions_shown - 1]
			var node = create_action_node(new_action)
			button_box.add_child(node)
	
		if action_queue.is_empty():
			minigame_finished.emit()

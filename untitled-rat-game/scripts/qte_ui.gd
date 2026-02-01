extends CanvasLayer

# QTE UI - Visual interface for Quick Time Events

@onready var overlay = $Overlay
@onready var title_label = $Overlay/CenterContainer/VBoxContainer/TitleLabel
@onready var key_container = $Overlay/CenterContainer/VBoxContainer/KeyContainer
@onready var timer_bar = $Overlay/CenterContainer/VBoxContainer/TimerBar
@onready var timer_label = $Overlay/CenterContainer/VBoxContainer/TimerLabel
@onready var feedback_label = $Overlay/CenterContainer/VBoxContainer/FeedbackLabel
@onready var success_sound_player = $SuccessSound
@onready var miss_sound_player = $MissSound
# Arrow keys sprite atlas
var atlas = preload("res://assets/arrow-keys.png")
const ATLAS_COORDS = {
	'up': Rect2i(0, 0, 16, 16),
	'left': Rect2i(32, 0, 16, 16),
	'right': Rect2i(64, 0, 16, 16),
	'down': Rect2i(96, 0, 16, 16),
	'space': Rect2i(128, 0, 32, 16)  # Space bar is wider (2 blocks)
}

# Key icon references
var key_icons = []

# Animation
var pulse_time = 0.0
var showing_feedback = false
var feedback_timer = 0.0

func _ready():
	# Connect to QTE System signals
	QTESystem.qte_started.connect(_on_qte_started)
	QTESystem.qte_key_pressed.connect(_on_qte_key_pressed)
	QTESystem.qte_completed.connect(_on_qte_completed)
	QTESystem.qte_progress_updated.connect(_on_qte_progress_updated)
	
	# Hide by default
	hide_ui()
	
	print("[QTE UI] Initialized and connected to QTE System")

func _process(delta):
	# Pulse animation for current key
	if visible and key_icons.size() > 0:
		pulse_time += delta * 5.0  # Speed of pulse
		var pulse = (sin(pulse_time) + 1.0) / 2.0  # 0 to 1
		
		# Find current key and pulse it
		for i in range(key_icons.size()):
			var icon = key_icons[i]
			if icon.modulate == Color.WHITE or icon.modulate.g > 0.9:
				# Current key - make it pulse
				var scale_factor = 1.0 + pulse * 0.3
				icon.scale = Vector2(scale_factor, scale_factor)
	
	# Handle feedback message fadeout
	if showing_feedback:
		feedback_timer -= delta
		if feedback_timer <= 0:
			feedback_label.visible = false
			showing_feedback = false

func _on_qte_started(sequence: Array):
	print("[QTE UI] QTE Started with sequence: %s" % [sequence])
	
	# Clear previous keys
	for icon in key_icons:
		icon.queue_free()
	key_icons.clear()
	
	# Create key icons
	for i in range(sequence.size()):
		var key_action = sequence[i]
		var icon = create_key_icon(key_action)
		
		if icon:
			# Style
			icon.modulate = Color.DIM_GRAY  # Not yet reached
			
			# Add to container
			key_container.add_child(icon)
			key_icons.append(icon)
	
	# Highlight first key
	if key_icons.size() > 0:
		key_icons[0].modulate = Color.WHITE
	
	# Reset timer
	timer_bar.value = 100
	
	# Clear feedback
	feedback_label.visible = false
	feedback_label.text = ""
	
	# Show UI
	show_ui()

func _on_qte_key_pressed(correct: bool, key_index: int):
	if key_index >= key_icons.size():
		return
	
	if correct:
		print("[QTE UI] Key %d pressed correctly" % key_index)
		# Mark as completed (green)
		key_icons[key_index].modulate = Color.GREEN
		key_icons[key_index].scale = Vector2.ONE
		
		# Play sound
		success_sound_player.play()

		# Highlight next key if exists
		if key_index + 1 < key_icons.size():
			key_icons[key_index + 1].modulate = Color.WHITE
	else:
		print("[QTE UI] Wrong key pressed!")
		# Mark current key as failed (red)
		key_icons[key_index].modulate = Color.RED
		
		# Play sound
		miss_sound_player.play()
		
		show_feedback("WRONG KEY!", Color.RED)

func _on_qte_completed(success: bool):
	print("[QTE UI] QTE Completed - Success: %s" % success)
	
	if success:
		show_feedback("SUCCESS!", Color.GREEN)
	else:
		show_feedback("FAILED!", Color.RED)
	
	# Hide UI after short delay
	await get_tree().create_timer(0.5).timeout
	hide_ui()

func _on_qte_progress_updated(time_remaining: float, max_time: float):
	# Update timer bar
	var percentage = (time_remaining / max_time) * 100.0
	timer_bar.value = percentage
	
	# Update timer label
	timer_label.text = "Time: %.1fs" % time_remaining
	
	# Change color when running out of time
	if percentage < 25:
		timer_bar.modulate = Color.RED
	elif percentage < 50:
		timer_bar.modulate = Color.YELLOW
	else:
		timer_bar.modulate = Color.WHITE

func show_ui():
	overlay.visible = true
	pulse_time = 0.0

func hide_ui():
	overlay.visible = false

func show_feedback(message: String, color: Color):
	feedback_label.text = message
	feedback_label.modulate = color
	feedback_label.visible = true
	showing_feedback = true
	feedback_timer = 1.0

func create_key_icon(action: String) -> TextureRect:
	# Map input actions to arrow directions
	var arrow_key = get_arrow_key_for_action(action)
	
	if not arrow_key in ATLAS_COORDS:
		# Fallback: create a simple label if we don't have an icon
		var label = Label.new()
		label.text = "[?]"
		label.add_theme_font_size_override("font_size", 48)
		return null
	
	# Create texture rect with the appropriate arrow icon
	var icon = TextureRect.new()
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = atlas
	atlas_texture.region = ATLAS_COORDS[arrow_key]
	
	icon.texture = atlas_texture
	icon.custom_minimum_size = Vector2(64, 64)  # Make icons nice and big
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	return icon

func get_arrow_key_for_action(action: String) -> String:
	# Map game actions to arrow key directions in the sprite
	match action:
		"ui_left", "left":
			return "left"
		"ui_right", "right":
			return "right"
		"up":
			return "up"
		"down":
			return "down"
		"ui_accept", "space":
			return "space"
		_:
			return "up"  # Default fallback

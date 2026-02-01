extends CanvasLayer

# QTE UI - Visual interface for Quick Time Events

@onready var overlay = $Overlay
@onready var title_label = $Overlay/CenterContainer/VBoxContainer/TitleLabel
@onready var key_container = $Overlay/CenterContainer/VBoxContainer/KeyContainer
@onready var timer_bar = $Overlay/CenterContainer/VBoxContainer/TimerBar
@onready var timer_label = $Overlay/CenterContainer/VBoxContainer/TimerLabel
@onready var feedback_label = $Overlay/CenterContainer/VBoxContainer/FeedbackLabel

# Key label references
var key_labels = []

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
	if visible and key_labels.size() > 0:
		pulse_time += delta * 5.0  # Speed of pulse
		var pulse = (sin(pulse_time) + 1.0) / 2.0  # 0 to 1
		
		# Find current key and pulse it
		for i in range(key_labels.size()):
			var label = key_labels[i]
			if label.modulate == Color.WHITE or label.modulate.g > 0.9:
				# Current key - make it pulse
				var scale_factor = 1.0 + pulse * 0.2
				label.scale = Vector2(scale_factor, scale_factor)
	
	# Handle feedback message fadeout
	if showing_feedback:
		feedback_timer -= delta
		if feedback_timer <= 0:
			feedback_label.visible = false
			showing_feedback = false

func _on_qte_started(sequence: Array):
	print("[QTE UI] QTE Started with sequence: %s" % [sequence])
	
	# Clear previous keys
	for label in key_labels:
		label.queue_free()
	key_labels.clear()
	
	# Create key labels
	for i in range(sequence.size()):
		var key_action = sequence[i]
		var label = Label.new()
		
		# Format the key name nicely
		var key_text = format_key_name(key_action)
		label.text = "[%s]" % key_text
		
		# Style
		label.add_theme_font_size_override("font_size", 48)
		label.modulate = Color.DIM_GRAY  # Not yet reached
		
		# Add to container
		key_container.add_child(label)
		key_labels.append(label)
	
	# Highlight first key
	if key_labels.size() > 0:
		key_labels[0].modulate = Color.WHITE
	
	# Reset timer
	timer_bar.value = 100
	
	# Clear feedback
	feedback_label.visible = false
	feedback_label.text = ""
	
	# Show UI
	show_ui()

func _on_qte_key_pressed(correct: bool, key_index: int):
	if key_index >= key_labels.size():
		return
	
	if correct:
		print("[QTE UI] Key %d pressed correctly" % key_index)
		# Mark as completed (green)
		key_labels[key_index].modulate = Color.GREEN
		key_labels[key_index].scale = Vector2.ONE
		
		# Highlight next key if exists
		if key_index + 1 < key_labels.size():
			key_labels[key_index + 1].modulate = Color.WHITE
	else:
		print("[QTE UI] Wrong key pressed!")
		# Mark current key as failed (red)
		key_labels[key_index].modulate = Color.RED
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

func format_key_name(action: String) -> String:
	# Convert action names to display names
	match action:
		"left":
			return "LEFT"
		"right":
			return "RIGHT"
		"ui_accept":
			return "SPACE"
		"up":
			return "UP"
		"down":
			return "DOWN"
		_:
			return action.to_upper()

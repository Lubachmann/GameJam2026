extends Node2D

# Game timer settings
const GAME_DURATION = 60.0  # 1 minute in seconds

# Timer state
var time_remaining: float = GAME_DURATION
var game_active: bool = true

# Reference to the timer label
@onready var timer_label: Label = $UI/TimerLabel

func _ready() -> void:
	time_remaining = GAME_DURATION
	game_active = true
	update_timer_display()

func _process(delta: float) -> void:
	if not game_active:
		return
	
	# Count down the timer
	time_remaining -= delta
	
	# Update the display
	update_timer_display()
	
	# Check if time has run out
	if time_remaining <= 0:
		time_remaining = 0
		game_over()

func update_timer_display() -> void:
	# Format time as MM:SS
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Change color based on urgency
	if time_remaining <= 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining <= 30:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func game_over() -> void:
	game_active = false
	timer_label.text = "TIME'S UP!"
	print("Game Over! Time ran out.")
	
	# Pause the game (but keep UI running)
	get_tree().paused = true
	
	# You can add game over screen logic here
	# For example: load game over scene, show score, etc.

extends Node2D

# Game timer settings
const GAME_DURATION = 120.0  # 1 minute in seconds
const GAME_OVER_DELAY = 3.0  # seconds to wait before returning to menu

# Timer state
var time_remaining: float = GAME_DURATION
var game_active: bool = true
var game_over_timer: float = 0.0
var waiting_for_menu: bool = false

# Reference to the timer label and cage
@onready var timer_label: Label = $UI/TimerLabel
@onready var cage = $cage

func _ready() -> void:
	time_remaining = GAME_DURATION
	game_active = true
	waiting_for_menu = false
	update_timer_display()

func _process(delta: float) -> void:
	# Handle game over delay
	if waiting_for_menu:
		game_over_timer -= delta
		if game_over_timer <= 0:
			return_to_menu()
		return
	
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
	
	# Get the final tissue count
	var tissues_stolen = cage.tissue_count
	
	# Save the score
	ScoreManager.save_score(tissues_stolen)
	
	# Display game over message
	timer_label.text = "TIME'S UP!"
	timer_label.add_theme_color_override("font_color", Color.RED)
	
	print("Game Over! Tissues stolen: %d" % tissues_stolen)
	
	# Start the delay timer
	waiting_for_menu = true
	game_over_timer = GAME_OVER_DELAY
	
	# Pause the game (but keep UI running)
	get_tree().paused = true

func return_to_menu() -> void:
	# Unpause before changing scenes
	get_tree().paused = false
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

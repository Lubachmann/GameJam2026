extends Control

# Second tutorial screen - shows for 3 seconds then goes to game

const DISPLAY_DURATION = 3.0  # seconds
var timer: float = 0.0

func _ready() -> void:
	timer = DISPLAY_DURATION
	print("[Tutorial 2] Showing second tutorial for %.1f seconds" % DISPLAY_DURATION)

func _process(delta: float) -> void:
	timer -= delta
	
	if timer <= 0:
		# Time's up, go to game
		print("[Tutorial 2] Transitioning to game scene")
		get_tree().change_scene_to_file("res://scenes/game.tscn")

extends Control

@onready var high_score_container = $HighScoresContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	display_high_scores()

func display_high_scores() -> void:
	# Get top 3 scores
	var top_scores = ScoreManager.get_top_scores(3)
	
	# Update the labels
	for i in range(3):
		var label_node = high_score_container.get_node("Score" + str(i + 1))
		if i < top_scores.size():
			label_node.text = "%d. %d tissues" % [i + 1, top_scores[i]]
		else:
			label_node.text = "%d. ---" % [i + 1]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()

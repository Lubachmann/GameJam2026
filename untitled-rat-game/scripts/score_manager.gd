extends Node

# Score persistence system
const SAVE_FILE_PATH = "user://high_scores.save"
const MAX_HIGH_SCORES = 10

var high_scores: Array = []

func _ready():
	load_scores()

func save_score(tissues_stolen: int) -> void:
	# Add the new score
	high_scores.append(tissues_stolen)
	
	# Sort in descending order (highest first)
	high_scores.sort()
	high_scores.reverse()
	
	# Keep only the top MAX_HIGH_SCORES
	if high_scores.size() > MAX_HIGH_SCORES:
		high_scores.resize(MAX_HIGH_SCORES)
	
	# Save to file
	save_scores()
	
	print("[ScoreManager] Score saved: %d tissues. High scores: %s" % [tissues_stolen, str(high_scores)])

func get_top_scores(count: int = 3) -> Array:
	var top = []
	for i in range(min(count, high_scores.size())):
		top.append(high_scores[i])
	return top

func save_scores() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_scores)
		file.close()
		print("[ScoreManager] Scores saved to file")
	else:
		push_error("Failed to save scores to file")

func load_scores() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			high_scores = file.get_var()
			file.close()
			print("[ScoreManager] Loaded %d high scores" % high_scores.size())
		else:
			push_error("Failed to load scores from file")
	else:
		print("[ScoreManager] No save file found, starting with empty scores")
		high_scores = []

func clear_scores() -> void:
	high_scores.clear()
	save_scores()
	print("[ScoreManager] All scores cleared")

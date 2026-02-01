extends Node

# Background music manager - plays continuously across all scenes

var music_player: AudioStreamPlayer

func _ready():
	# Create audio player for background music
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://assets/fx/UntitledRatGame.wav")
	music_player.bus = "Master"
	music_player.autoplay = true
	music_player.volume_db = 0.0  # Adjust volume as needed (0 = normal, negative = quieter)
	add_child(music_player)
	
	# Connect to the finished signal to loop the music
	music_player.finished.connect(_on_music_finished)
	
	# Start playing
	music_player.play()
	
	print("[Background Music] Started playing soundtrack")

func _on_music_finished():
	# Loop the music when it finishes
	music_player.play()

func set_volume(volume_db: float):
	if music_player:
		music_player.volume_db = volume_db

func stop_music():
	if music_player:
		music_player.stop()

func play_music():
	if music_player and not music_player.playing:
		music_player.play()

extends Node

# QTE System - Manages Quick Time Events for mask equipping
# This is an autoload singleton

# Configuration constants
const TIME_LIMIT = 4.0  # seconds for completing QTE
const COOLDOWN_DURATION = 2.0  # seconds before can retry after failure
const INITIAL_DIFFICULTY = 3  # starting number of keys
const MAX_DIFFICULTY = 6  # maximum number of keys
const TIME_SCALE_FACTOR = 0.2  # game speed during QTE (20%)

# QTE State
enum QTEState { INACTIVE, ACTIVE, SUCCESS, FAILURE }
var current_state = QTEState.INACTIVE

# Key sequence
var available_keys = ["left", "right", "ui_accept", "up", "down"]
var current_sequence = []
var current_key_index = 0

# Difficulty progression
var difficulty_level = INITIAL_DIFFICULTY

# Timing
var time_remaining = 0.0
var original_time_scale = 1.0

# Cooldown
var cooldown_active = false
var cooldown_timer = 0.0

# Reference to rat player
var rat_player = null

# Signals for UI and game events
signal qte_started(sequence: Array)
signal qte_key_pressed(correct: bool, key_index: int)
signal qte_completed(success: bool)
signal cooldown_started(duration: float)
signal cooldown_ended
signal qte_progress_updated(time_remaining: float, max_time: float)

func _ready():
	print("[QTE System] Initialized - Difficulty: %d keys" % difficulty_level)

func _process(delta):
	# Handle cooldown
	if cooldown_active:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			cooldown_active = false
			cooldown_ended.emit()
			print("[QTE System] Cooldown ended")
	
	# Handle active QTE
	if current_state == QTEState.ACTIVE:
		# Use unscaled delta since game time is slowed
		var actual_delta = delta / Engine.time_scale
		time_remaining -= actual_delta
		qte_progress_updated.emit(time_remaining, TIME_LIMIT)
		
		if time_remaining <= 0:
			fail_qte()

func _input(event):
	# Debug: F1 to reset difficulty
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F1:
			reset_difficulty()
			return
	
	if current_state != QTEState.ACTIVE:
		return
	
	# Check if any key action was just pressed
	if event.is_pressed() and not event.is_echo():
		for key_action in available_keys:
			if event.is_action_pressed(key_action):
				check_key_input(key_action)
				break

func start_mask_qte(player):
	# Check if on cooldown
	if cooldown_active:
		print("[QTE System] Failed to start - on cooldown (%.1fs remaining)" % cooldown_timer)
		# Could show a message here
		return false
	
	# Check if already active
	if current_state == QTEState.ACTIVE:
		print("[QTE System] QTE already active")
		return false
	
	rat_player = player
	current_state = QTEState.ACTIVE
	current_key_index = 0
	time_remaining = TIME_LIMIT
	
	# Generate key sequence
	generate_sequence()
	
	# Slow down time
	original_time_scale = Engine.time_scale
	Engine.time_scale = TIME_SCALE_FACTOR
	
	print("[QTE System] Started - Difficulty: %d keys, Sequence: %s" % [difficulty_level, current_sequence])
	qte_started.emit(current_sequence)
	
	return true

func generate_sequence():
	current_sequence.clear()
	var keys_to_generate = min(difficulty_level, MAX_DIFFICULTY)
	
	for i in range(keys_to_generate):
		# Pick random key
		var random_key = available_keys.pick_random()
		current_sequence.append(random_key)

func check_key_input(pressed_key: String):
	if current_key_index >= current_sequence.size():
		return
	
	var expected_key = current_sequence[current_key_index]
	
	if pressed_key == expected_key:
		# Correct key!
		print("[QTE System] Correct key %d/%d: %s" % [current_key_index + 1, current_sequence.size(), pressed_key])
		qte_key_pressed.emit(true, current_key_index)
		current_key_index += 1
		
		# Check if sequence complete
		if current_key_index >= current_sequence.size():
			complete_qte()
	else:
		# Wrong key!
		print("[QTE System] Wrong key! Expected: %s, Got: %s" % [expected_key, pressed_key])
		qte_key_pressed.emit(false, current_key_index)
		fail_qte()

func complete_qte():
	print("[QTE System] SUCCESS! Completing QTE")
	current_state = QTEState.SUCCESS
	
	# Restore time scale
	Engine.time_scale = original_time_scale
	
	# Increase difficulty for next time
	if difficulty_level < MAX_DIFFICULTY:
		difficulty_level += 1
		print("[QTE System] Difficulty increased to %d keys" % difficulty_level)
	
	# Equip the mask
	if rat_player and rat_player.has_method("equip_mask"):
		rat_player.equip_mask()
	
	# Emit completion signal
	qte_completed.emit(true)
	
	# Reset state
	current_state = QTEState.INACTIVE
	rat_player = null

func fail_qte():
	print("[QTE System] FAILED! QTE failed - starting cooldown")
	current_state = QTEState.FAILURE
	
	# Restore time scale
	Engine.time_scale = original_time_scale
	
	# Start cooldown
	cooldown_active = true
	cooldown_timer = COOLDOWN_DURATION
	cooldown_started.emit(COOLDOWN_DURATION)
	
	# Emit failure signal
	qte_completed.emit(false)
	
	# Reset state
	current_state = QTEState.INACTIVE
	rat_player = null

# Debug function to reset difficulty
func reset_difficulty():
	difficulty_level = INITIAL_DIFFICULTY
	print("[QTE System] Difficulty reset to %d keys" % difficulty_level)

func get_difficulty() -> int:
	return difficulty_level

func is_active() -> bool:
	return current_state == QTEState.ACTIVE

func is_on_cooldown() -> bool:
	return cooldown_active

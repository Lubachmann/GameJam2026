extends Area2D

@onready var instruction_label: Label = $InstructionLabel
var player_nearby: bool = false

func _ready() -> void:
	# Connect signals for player detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hide label initially
	if instruction_label:
		instruction_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	# Check if the player entered
	if body.name == "Rat":
		player_nearby = true
		if instruction_label:
			instruction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	# Check if the player left
	if body.name == "Rat":
		player_nearby = false
		if instruction_label:
			instruction_label.visible = false

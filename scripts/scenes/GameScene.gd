extends Control

@onready var king_label = $CharacterLayer/King/DialogBubble/Panel/DialogLabel
@onready var keshar_label = $CharacterLayer/Keshar/DialogBubble/Panel/DialogLabel
@onready var visitor_label = $CharacterLayer/Visitor/DialogBubble/Panel/DialogLabel

@onready var choice_container = $ChoicePanel/ChoiceContainer
@onready var choice_panel = $ChoicePanel
@onready var day_label = $TopBar/DayLabel
@onready var continue_btn = $TopBar/ContinueButton

var DialogueSystem = preload("res://scripts/systems/DialogueSystem.gd")
var ChoiceSystem = preload("res://scripts/systems/ChoiceSystem.gd")
var UISystem = preload("res://scripts/systems/UISystem.gd")

var dialogue_system
var choice_system
var ui_system

var day_data
var visitor_index = 0
var current_choices = []

func _ready():
	dialogue_system = DialogueSystem.new()
	add_child(dialogue_system)

	choice_panel.visible = false
	choice_system = ChoiceSystem.new()
	add_child(choice_system)

	ui_system = UISystem.new()
	add_child(ui_system)

	dialogue_system.setup(
		king_label,
		keshar_label,
		visitor_label,
	)

	choice_system.setup(choice_container)
	continue_btn.visible = false
	ui_system.setup(day_label,continue_btn)

	dialogue_system.dialogue_finished.connect(_on_dialogue_finished)
	choice_system.choice_selected.connect(_on_choice_selected)

	continue_btn.pressed.connect(_on_continue)

	start_day(1)

func start_day(day:int):
	day_data = StoryLoader.load_day(day)
	visitor_index = 0

	ui_system.set_day(day,day_data.get("title",""))

	play_morning()

func play_morning():
	var briefing = day_data["morning_briefing"]

	dialogue_system.start_dialogues(
		briefing["dialogues"]
	)

func _on_dialogue_finished():
	if current_choices.size() > 0:
		choice_panel.visible = true
		choice_system.show_choices(current_choices)

	elif visitor_index < day_data["visitors"].size():
		play_visitor()

	else:
		play_night()

func play_visitor():
	var v = day_data["visitors"][visitor_index]
	choice_panel.visible = false

	dialogue_system.start_dialogues(
		v["dialogues"]
	)
	
	current_choices = v.get("choices", [])

func _on_continue():
	continue_btn.visible = false
	GameState.current_day += 1

	start_day(GameState.current_day)
	
func _input(event):
	if choice_panel.visible:
		return
		
	if event.is_action_pressed("next_dialog"):
		dialogue_system.next()

func _on_choice_selected(choice):
	choice_panel.visible = false
	
	if choice.has("effects"):
		GameState.apply_effects(choice["effects"])
	
	current_choices = []
	visitor_index += 1
	
	get_viewport().set_input_as_handled()
	play_visitor()

func play_night():
	var night = day_data["night_event"]

	dialogue_system.start_dialogues(
		night["dialogues"]
	)
	
	await dialogue_system.dialogue_finished

	continue_btn.visible = true

extends Control

@onready var king_label    = $CharacterLayer/King/DialogBubble/Panel/DialogLabel
@onready var keshar_label  = $CharacterLayer/Keshar/DialogBubble/Panel/DialogLabel
@onready var visitor_label = $CharacterLayer/Visitor/DialogBubble/Panel/DialogLabel

@onready var king_panel    = $CharacterLayer/King/DialogBubble
@onready var keshar_panel  = $CharacterLayer/Keshar/DialogBubble
@onready var visitor_panel = $CharacterLayer/Visitor/DialogBubble

@onready var stability_val = $StatPanel/MarginContainer/HBoxContainer/Stability/Val
@onready var trust_val     = $StatPanel/MarginContainer/HBoxContainer/Trust/Val
@onready var treasury_val  = $StatPanel/MarginContainer/HBoxContainer/Treasury/Val
@onready var military_val  = $StatPanel/MarginContainer/HBoxContainer/Military/Val
@onready var influence_val = $StatPanel/MarginContainer/HBoxContainer/Influence/Val

@onready var choice_container = $ChoicePanel/ChoiceContainer
@onready var choice_panel     = $ChoicePanel
@onready var day_label        = $TopBar/MarginContainer/DayLabel
@onready var toast            = $ToastLayer/ToastContainer
@onready var phase_overlay    = $PhaseOverlay
@onready var background       = $Background

var DialogueSystem = preload("res://scripts/systems/DialogueSystem.gd")
var ChoiceSystem   = preload("res://scripts/systems/ChoiceSystem.gd")
var UISystem       = preload("res://scripts/systems/UISystem.gd")
var ToastSystem    = preload("res://scripts/systems/ToastSystem.gd")
var DayTransition  = preload("res://scenes/gameplay/DayTransition.tscn")

var dialogue_system
var choice_system
var ui_system
var toast_system
var day_transition

enum Phase {
	MORNING,
	VISITOR,
	NIGHT
}

var day_data
var visitor_index   = 0
var current_choices = []
var phase: Phase    = Phase.MORNING
var _resolving      := false
var _is_changing_day  := false
var _is_transitioning := false

var BG_MORNING      = preload("res://assets/sprites/background/park.png")
var BG_VISITOR      = preload("res://assets/sprites/background/throne_day.png")
var BG_NIGHT_THRONE = preload("res://assets/sprites/background/throne_night.png")
var BG_NIGHT_BEDROOM = preload("res://assets/sprites/background/bedroom.png")

const NIGHT_BG_OVERRIDE: Dictionary = {
	3: "bedroom",
	7: "bedroom",
}

func _ready() -> void:
	dialogue_system = DialogueSystem.new()
	add_child(dialogue_system)

	choice_system = ChoiceSystem.new()
	add_child(choice_system)

	ui_system = UISystem.new()
	add_child(ui_system)

	toast_system = ToastSystem.new()
	add_child(toast_system)
	toast_system.setup(toast)

	day_transition = DayTransition.instantiate()
	add_child(day_transition)
	day_transition.next_day_pressed.connect(_on_day_transition_continue)

	dialogue_system.setup(king_label, keshar_label, visitor_label)
	choice_system.setup(choice_container)
	ui_system.setup(day_label)
	ui_system.setup_stats(stability_val, trust_val, treasury_val, military_val, influence_val)

	dialogue_system.dialogue_finished.connect(_on_dialogue_finished)
	choice_system.choice_selected.connect(_on_choice_selected)
	choice_panel.visible = false

	_begin_day(1)
	

# ======================================
# DAY & TRANSITION
func _load_day(day: int) -> void:
	day_data        = StoryLoader.load_day(day)
	visitor_index   = 0
	_resolving      = false
	current_choices = []

func _begin_day(day: int) -> void:
	_load_day(day)
	ui_system.set_day(day, day_data.get("title", ""))
	play_morning()

func _start_day_with_transition(day: int) -> void:
	_load_day(day)
	day_transition.play(day, day_data.get("title", ""))

func _on_day_transition_continue() -> void:
	background.texture = BG_MORNING
	
	await day_transition.hide_transition()
	
	ui_system.set_day(GameState.current_day, day_data.get("title", ""))
	_clear_all_dialogues()
	_is_changing_day = false
	play_morning()

func _phase_transition(new_bg: Texture, duration := 0.4) -> void:
	_is_transitioning = true
	phase_overlay.visible = true
	phase_overlay.modulate.a = 0.0

	var tw = create_tween()
	tw.tween_property(phase_overlay, "modulate:a", 1.0, duration * 0.5)
	await tw.finished

	background.texture = new_bg

	var tw2 = create_tween()
	tw2.tween_property(phase_overlay, "modulate:a", 0.0, duration * 0.5)
	await tw2.finished

	phase_overlay.visible = false
	_is_transitioning = false


# ======================================
# PLAY EVENT
func play_morning() -> void:
	phase = Phase.MORNING
	dialogue_system.start_dialogues(day_data["morning_briefing"]["dialogues"])
	
func play_visitor() -> void:
	phase = Phase.VISITOR
	if not _has_more_visitors():
		play_night()
		return
	var v = day_data["visitors"][visitor_index]
	choice_panel.visible = false
	current_choices = v.get("choices", [])
	dialogue_system.start_dialogues(v["dialogues"])

func play_night() -> void:
	phase = Phase.NIGHT
	var night = day_data["night_event"]
	current_choices = night.get("choices", [])
	dialogue_system.start_dialogues(night["dialogues"])


# ======================================
# DIALOG
func _on_dialogue_finished() -> void:
	if _resolving:
		return

	if current_choices.size() > 0:
		choice_panel.visible = true
		choice_system.show_choices(current_choices)
		return

	if phase == Phase.MORNING:
		dialogue_system.force_stop()
		await _phase_transition(BG_VISITOR, 1.0)
		play_visitor()

	elif phase == Phase.VISITOR:
		dialogue_system.force_stop()
		if _has_more_visitors():
			await _phase_transition(BG_VISITOR, 1.0)
			play_visitor()
		else:
			await _phase_transition(_get_night_bg(), 0.6)
			play_night()

	elif phase == Phase.NIGHT:
		if _is_changing_day:
			return
		_is_changing_day = true
		GameState.current_day += 1
		_start_day_with_transition(GameState.current_day)

func _clear_all_dialogues() -> void:
	king_label.text    = ""
	keshar_label.text  = ""
	visitor_label.text = ""
	king_panel.visible    = false
	keshar_panel.visible  = false
	visitor_panel.visible = false


# ======================================
# CHOICE
func _on_choice_selected(choice: Dictionary) -> void:
	current_choices = []
	choice_panel.visible = false
	_resolving = true
	await _resolve_choice(choice)
	_resolving = false
	
	if phase == Phase.VISITOR:
		visitor_index += 1

func _resolve_choice(choice: Dictionary) -> void:
	var king_follow := GameState.king_follows_advice()

	var effects: Dictionary = choice.get("effects", {}) if king_follow \
		else choice.get("king_refuse_effect", {})

	var ps: String = choice.get("personality_shift", "")
	if not ps.is_empty():
		effects = effects.duplicate()
		effects["personality_shift"] = ps

	GameState.stage_effects(effects, king_follow)
	ui_system.begin_deferred_stats()

	var extra: Array = []
	if choice.get("keshar_text", "") != "":
		extra.append({"speaker": "Keshar", "text": choice["keshar_text"]})

	if king_follow:
		if choice.get("king_follow_text", "") != "":
			extra.append({"speaker": "Raja Aldric", "text": choice["king_follow_text"]})
		if choice.has("visitor_king_follow_response"):
			extra.append({"speaker": "Visitor", "text": choice["visitor_king_follow_response"]})
	else:
		if choice.get("king_refuse_text", "") != "":
			extra.append({"speaker": "Raja Aldric", "text": choice["king_refuse_text"]})
		if choice.has("visitor_king_refuse_response"):
			extra.append({"speaker": "Visitor", "text": choice["visitor_king_refuse_response"]})

	if extra.size() > 0:
		dialogue_system.start_dialogues(extra)
		await dialogue_system.dialogue_finished

	ui_system.commit_deferred_stats()
	toast_system.show_effects(effects, king_follow)
	

# ======================================
func _has_more_visitors() -> bool:
	return visitor_index < day_data["visitors"].size()

func _get_night_bg() -> Texture:
	var override = NIGHT_BG_OVERRIDE.get(GameState.current_day, "throne")
	return BG_NIGHT_BEDROOM if override == "bedroom" else BG_NIGHT_THRONE
	
func _input(event: InputEvent) -> void:
	if choice_panel.visible or day_transition.visible or _is_transitioning:
		return
	if event.is_action_pressed("next_dialog"):
		dialogue_system.next()

extends Control

@onready var king_label    = $CharacterLayer/King/DialogBubble/Panel/DialogLabel
@onready var keshar_label  = $CharacterLayer/Keshar/DialogBubble/Panel/DialogLabel
@onready var visitor_label = $CharacterLayer/Visitor/DialogBubble/Panel/DialogLabel

@onready var king_panel    = $CharacterLayer/King/DialogBubble
@onready var keshar_panel  = $CharacterLayer/Keshar/DialogBubble
@onready var visitor_panel = $CharacterLayer/Visitor/DialogBubble

@onready var king_sprite    = $CharacterLayer/King/Sprite2D
@onready var keshar_sprite  = $CharacterLayer/Keshar/Sprite2D
@onready var visitor_sprite = $CharacterLayer/Visitor/Sprite2D

@onready var stability_val = $StatPanel/MarginContainer/HBoxContainer/Stability/Val
@onready var trust_val     = $StatPanel/MarginContainer/HBoxContainer/Trust/Val
@onready var treasury_val  = $StatPanel/MarginContainer/HBoxContainer/Treasury/Val
@onready var military_val  = $StatPanel/MarginContainer/HBoxContainer/Military/Val
@onready var influence_val = $StatPanel/MarginContainer/HBoxContainer/Influence/Val

@onready var choice_container = $ChoicePanel/ChoiceContainer
@onready var choice_panel     = $ChoicePanel
@onready var pause_menu       = $PauseMenu
@onready var day_label        = $TopBar/MarginContainer/HBoxContainer/DayLabel
@onready var toast            = $ToastLayer/ToastContainer
@onready var phase_overlay    = $PhaseOverlay
@onready var pause_overlay    = $PauseOverlay
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
var _exiting := false

var BG_MORNING      = preload("res://assets/sprites/background/park.png")
var BG_VISITOR      = preload("res://assets/sprites/background/throne_day.png")
var BG_NIGHT_THRONE = preload("res://assets/sprites/background/throne_night.png")
var BG_NIGHT_BEDROOM = preload("res://assets/sprites/background/bedroom.png")

# Posisi sprite
const POS_KIRI  := Vector2(363.0, 640.0)
const POS_KANAN := Vector2(1559.0, 611.0)
const POS_TENGAH := Vector2(963.0, 611.0)

# Bubble offset_left per posisi
const BUBBLE_KIRI  := 176.0
const BUBBLE_KANAN := 1370.0
const BUBBLE_TENGAH := 767.0

const CHOICE_OFFSET_KIRI   := 88.0
const CHOICE_OFFSET_TENGAH := 660.0

const CHARACTER_SPRITES = {
	"Raja Aldric":      preload("res://assets/sprites/character/king/flat.png"),
	"Keshar":           preload("res://assets/sprites/character/keshar/flat.png"),
	"Permaisuri Elara": preload("res://assets/sprites/character/queen/smile.png"),
	"Selim":            preload("res://assets/sprites/character/visitor/spy.png"),
}

const NIGHT_BG_OVERRIDE: Dictionary = {
	3: "bedroom",
	4: "bedroom",
	5: "bedroom",
	7: "bedroom",
}

func _ready() -> void:
	phase = Phase.MORNING
	visitor_index     = 0
	current_choices   = []
	_resolving        = false
	_is_changing_day  = false
	_is_transitioning = false
	_exiting          = false
	
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

	choice_panel.visible = false
	
	pause_menu.resume_pressed.connect(_on_resume_pressed)
	pause_menu.exit_pressed.connect(_on_exit_pressed)

	pause_menu.visible = false
	pause_overlay.visible = false
	
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	call_deferred("_begin_game")

func _begin_game() -> void:
	dialogue_system.dialogue_finished.connect(_on_dialogue_finished)
	choice_system.choice_selected.connect(_on_choice_selected)
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
	_clear_all_dialogues()
	_setup_characters(Phase.MORNING, day_data["morning_briefing"]["dialogues"])
	background.texture = BG_MORNING
	
	await day_transition.hide_transition()
	
	ui_system.set_day(GameState.current_day, day_data.get("title", ""))
	_is_changing_day = false
	play_morning(true)

func _phase_transition(new_bg: Texture, duration := 0.4, on_covered: Callable = Callable()) -> void:
	_is_transitioning = true
	phase_overlay.visible = true
	phase_overlay.modulate.a = 0.0

	var tw = create_tween()
	tw.tween_property(phase_overlay, "modulate:a", 1.0, duration * 0.5)
	await tw.finished

	background.texture = new_bg
	if on_covered.is_valid():
		on_covered.call()

	var tw2 = create_tween()
	tw2.tween_property(phase_overlay, "modulate:a", 0.0, duration * 0.5)
	await tw2.finished

	phase_overlay.visible = false
	_is_transitioning = false
	
func _show_to_be_continued() -> void:
	phase_overlay.visible = true
	phase_overlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(phase_overlay, "modulate:a", 1.0, 1.0)
	await tw.finished

	var tbc_label = Label.new()
	tbc_label.text = "To Be Continued..."
	tbc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tbc_label.add_theme_font_size_override("font_size", 48)
	tbc_label.modulate.a = 0.0
	tbc_label.position = Vector2(0, 460)
	tbc_label.size = Vector2(1920, 80)
	add_child(tbc_label)

	var tw2 = create_tween()
	tw2.tween_property(tbc_label, "modulate:a", 1.0, 0.8)
	await tw2.finished

	await get_tree().create_timer(2.0).timeout

	var btn = Button.new()
	btn.text = "Kembali ke Menu Utama"
	btn.modulate.a = 0.0
	btn.position = Vector2(760, 580)
	btn.size = Vector2(400, 60)
	add_child(btn)

	var tw3 = create_tween()
	tw3.tween_property(btn, "modulate:a", 1.0, 0.5)
	await tw3.finished

	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
	)
	btn.grab_focus()
	

# ======================================
# PLAY EVENT
func play_morning(skip_setup := false) -> void:
	phase = Phase.MORNING
	var dialogues = day_data["morning_briefing"]["dialogues"]
	_setup_characters(Phase.MORNING, dialogues)
	if not skip_setup:
		_setup_characters(Phase.MORNING, dialogues)
	dialogue_system.start_dialogues(dialogues)
	
func play_visitor(skip_setup := false) -> void:
	phase = Phase.VISITOR
	if not _has_more_visitors():
		play_night()
		return

	if not skip_setup:
		_setup_visitor_positions()
	
	king_sprite.visible    = true
	keshar_sprite.visible  = true
	visitor_sprite.visible = false

	var v = day_data["visitors"][visitor_index]
	choice_panel.visible = false
	current_choices = v.get("choices", [])
	dialogue_system.start_dialogues(v["dialogues"])

func play_night(skip_setup := false) -> void:
	phase = Phase.NIGHT
	var night = day_data["night_event"]
	if not skip_setup:
		_setup_characters(Phase.NIGHT, night["dialogues"])
	current_choices = night.get("choices", [])
	dialogue_system.start_dialogues(night["dialogues"])


# ======================================
# DIALOG
func _on_dialogue_finished() -> void:
	if _resolving or _exiting:
		return

	if current_choices.size() > 0:
		choice_panel.visible = true
		choice_system.show_choices(current_choices)
		return

	if phase == Phase.MORNING:
		dialogue_system.force_stop()
		var next_dialogues = day_data["visitors"][visitor_index]["dialogues"] if _has_more_visitors() else []
		await _phase_transition(BG_VISITOR, 2.0, func():
			_clear_all_dialogues()
			_setup_visitor_positions()
		)
		play_visitor(true)

	elif phase == Phase.VISITOR:
		dialogue_system.force_stop()
		if _has_more_visitors():
			await _phase_transition(BG_VISITOR, 1.0, func():
				_clear_all_dialogues()
				_setup_visitor_positions()
			)
			play_visitor()
		else:
			var night_dialogues = day_data["night_event"]["dialogues"]
			await _phase_transition(_get_night_bg(), 2.0, func():
				_clear_all_dialogues()
				_setup_characters(Phase.NIGHT, night_dialogues)
			)
			play_night()

	elif phase == Phase.NIGHT:
		if _is_changing_day:
			return
		_is_changing_day = true
		GameState.current_day += 1
		
		if GameState.current_day > 6:
			_show_to_be_continued()
			return
		
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
	var keshar_text = choice.get("keshar_text", "")
	if keshar_text != null and keshar_text != "":
		extra.append({"speaker": "Keshar", "text": keshar_text})

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

	if choice.get("visitor_response", "") != "":
		extra.append({"speaker": "Visitor", "text": choice["visitor_response"]})
	
	var extra_dlg: Array = choice.get("extra_dialogue", [])
	for d in extra_dlg:
		extra.append(d)
		
	if extra.size() > 0:
		dialogue_system.start_dialogues(extra)
		await dialogue_system.dialogue_finished

	ui_system.commit_deferred_stats()
	if phase != Phase.NIGHT:
		toast_system.show_effects(effects, king_follow)

# ======================================
# SPRITE CHARACTER
func _setup_characters(p: Phase, dialogues: Array) -> void:
	var other         = _get_other_character(dialogues)
	var other_texture = CHARACTER_SPRITES.get(other)

	if p == Phase.MORNING:
		# Keshar pindah ke KIRI
		keshar_sprite.position.x = POS_KIRI.x
		keshar_panel.offset_left = BUBBLE_KIRI
		keshar_sprite.visible    = true

		# King pindah ke KANAN
		king_sprite.position   = POS_KANAN
		king_panel.offset_left = BUBBLE_KANAN
		if other_texture:
			king_sprite.texture = other_texture
		king_sprite.visible = other_texture != null

		visitor_sprite.visible = false
		
		choice_panel.offset_left = CHOICE_OFFSET_TENGAH
		choice_panel.offset_right = CHOICE_OFFSET_TENGAH + 600.0

	elif p == Phase.NIGHT:
		# Keshar tetap KANAN
		keshar_sprite.position   = POS_KANAN
		keshar_panel.offset_left = BUBBLE_KANAN
		keshar_sprite.visible = true

		# Lawan bicara di KIRI pakai node Visitor
		visitor_sprite.position.x = POS_KIRI.x
		visitor_panel.offset_left = BUBBLE_KIRI
		if other_texture:
			visitor_sprite.texture = other_texture
		visitor_sprite.visible = other_texture != null

		king_sprite.visible = false
		
		choice_panel.offset_left = CHOICE_OFFSET_TENGAH
		choice_panel.offset_right = CHOICE_OFFSET_TENGAH + 600.0

func _setup_visitor_positions() -> void:
	king_sprite.position      = POS_TENGAH
	king_panel.offset_left    = BUBBLE_TENGAH
	keshar_sprite.position    = POS_KANAN
	keshar_panel.offset_left  = BUBBLE_KANAN
	visitor_sprite.position.x = POS_KIRI.x
	visitor_panel.offset_left = BUBBLE_KIRI
	choice_panel.offset_left  = CHOICE_OFFSET_KIRI
	choice_panel.offset_right = CHOICE_OFFSET_KIRI + 600.0
	
	
# ======================================
# PAUSE MENU
func toggle_pause():
	var is_paused = get_tree().paused

	if is_paused:
		_resume_game()
	else:
		_pause_game()

func _pause_game():
	choice_panel.process_mode = Node.PROCESS_MODE_DISABLED

	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	
	pause_overlay.modulate.a = 0.0
	pause_overlay.visible = true
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tw = create_tween()
	tw.tween_property(pause_overlay, "modulate:a", 0.5, 0.25)
	await tw.finished
	
	pause_menu.open()
	get_tree().paused = true

func _resume_game():
	choice_panel.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	Input.flush_buffered_events()
	
	await pause_menu.close()
	
	var tw = create_tween()
	tw.tween_property(pause_overlay, "modulate:a", 0.0, 0.2)
	await tw.finished
	
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	await get_tree().process_frame
	
func _on_resume_pressed():
	_resume_game()

func _on_exit_pressed():
	_exiting = true
	
	if dialogue_system.dialogue_finished.is_connected(_on_dialogue_finished):
		dialogue_system.dialogue_finished.disconnect(_on_dialogue_finished)
	
	dialogue_system.force_stop()
	_resolving = false
	_is_changing_day = false
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
	
	
# ======================================
func _has_more_visitors() -> bool:
	return visitor_index < day_data["visitors"].size()

func _get_night_bg() -> Texture:
	var override = NIGHT_BG_OVERRIDE.get(GameState.current_day, "throne")
	return BG_NIGHT_BEDROOM if override == "bedroom" else BG_NIGHT_THRONE
	
func _get_other_character(dialogues: Array) -> String:
	for d in dialogues:
		if d["speaker"] != "Keshar":
			return d["speaker"]
	return ""	
	
var _input_cooldown := false
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		return
	
	if get_tree().paused:
		return

	if choice_panel.visible or day_transition.visible or _is_transitioning:
		return

	if event.is_action_pressed("next_dialog"):
		if _input_cooldown:
			return

		dialogue_system.next()
		_input_cooldown = true
		await get_tree().process_frame
		_input_cooldown = false

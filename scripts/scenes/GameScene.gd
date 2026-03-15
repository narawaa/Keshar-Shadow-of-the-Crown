extends Control

# =============================================
# GameScene.gd — Controller gameplay utama
# Handles: dialog queue, pilihan, stats UI, checkpoint logic
# =============================================

enum Phase { MORNING, VISITOR, NIGHT, CRISIS, TRANSITION }

# --- UI Nodes ---
@onready var narrator_label: RichTextLabel = $MainPanel/NarratorBox/NarratorLabel
@onready var speaker_label: Label = $MainPanel/DialogBox/SpeakerLabel
@onready var dialog_label: RichTextLabel = $MainPanel/DialogBox/DialogLabel
@onready var choice_container: VBoxContainer = $MainPanel/ChoicePanel/ChoiceContainer
@onready var choice_panel: PanelContainer = $MainPanel/ChoicePanel
@onready var continue_btn: Button = $MainPanel/ContinueButton
@onready var day_label: Label = $TopBar/DayLabel
@onready var phase_label: Label = $TopBar/PhaseLabel
@onready var stability_bar: ProgressBar = $StatsPanel/StatsVBox/StatsGrid/StabilityBar
@onready var trust_bar: ProgressBar = $StatsPanel/StatsVBox/StatsGrid/TrustBar
@onready var influence_bar: ProgressBar = $StatsPanel/StatsVBox/StatsGrid/InfluenceBar
@onready var treasury_bar: ProgressBar = $StatsPanel/StatsVBox/StatsGrid/TreasuryBar
@onready var military_bar: ProgressBar = $StatsPanel/StatsVBox/StatsGrid/MilitaryBar
@onready var fear_bar: ProgressBar = $StatsPanel/StatsVBox/StatsGrid/FearBar
@onready var stability_val: Label = $StatsPanel/StatsVBox/StatsGrid/StabilityVal
@onready var trust_val: Label = $StatsPanel/StatsVBox/StatsGrid/TrustVal
@onready var influence_val: Label = $StatsPanel/StatsVBox/StatsGrid/InfluenceVal
@onready var treasury_val: Label = $StatsPanel/StatsVBox/StatsGrid/TreasuryVal
@onready var military_val: Label = $StatsPanel/StatsVBox/StatsGrid/MilitaryVal
@onready var fear_val: Label = $StatsPanel/StatsVBox/StatsGrid/FearVal
@onready var king_personality_label: Label = $StatsPanel/StatsVBox/KingPersonalityLabel
@onready var coup_indicator: Label = $StatsPanel/StatsVBox/CoupIndicator
@onready var king_response_panel: PanelContainer = $MainPanel/KingResponsePanel
@onready var king_response_label: RichTextLabel = $MainPanel/KingResponsePanel/KingResponseLabel
@onready var effect_popup: Label = $EffectPopup

# --- State ---
var current_phase: Phase = Phase.MORNING
var current_visitor_index: int = 0
var current_dialog_queue: Array = []
var dialog_index: int = 0
var current_visitor_data: Dictionary = {}
var day_data: Dictionary = {}
var current_night_data: Dictionary = {}

# =============================================
func _ready() -> void:
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.game_over.connect(_on_game_over)
	continue_btn.pressed.connect(_on_continue_pressed)
	_update_stats_ui()
	_start_day(GameState.current_day)

func _start_day(day: int) -> void:
	day_data = StoryLoader.load_day(day)
	if day_data.is_empty():
		push_error("GameScene: Tidak ada data untuk hari %d" % day)
		return
	day_label.text = "Hari %d — %s" % [day, day_data.get("title", "")]
	current_phase = Phase.MORNING
	current_visitor_index = 0
	_play_morning_briefing()

# =============================================
# MORNING
# =============================================
func _play_morning_briefing() -> void:
	phase_label.text = "🌅 Pagi"
	var briefing = day_data.get("morning_briefing", {})
	narrator_label.text = briefing.get("narrator", "")
	current_dialog_queue = briefing.get("dialogues", [])
	dialog_index = 0
	choice_panel.visible = false
	king_response_panel.visible = false
	continue_btn.visible = true
	_show_next_dialog_in_queue()

# =============================================
# VISITORS
# =============================================
func _next_visitor() -> void:
	var visitors = day_data.get("visitors", [])
	if current_visitor_index >= visitors.size():
		_play_night_event()
		return
	current_visitor_data = visitors[current_visitor_index]
	current_phase = Phase.VISITOR
	phase_label.text = "👤 Pengunjung %d — %s" % [
		current_visitor_index + 1,
		current_visitor_data.get("name", "Pengunjung")
	]
	narrator_label.text = current_visitor_data.get("narrator", "")
	current_dialog_queue = _resolve_conditional_dialogues(current_visitor_data)
	dialog_index = 0
	choice_panel.visible = false
	king_response_panel.visible = false
	continue_btn.visible = true
	_show_next_dialog_in_queue()

func _resolve_conditional_dialogues(data: Dictionary) -> Array:
	var cond_list = data.get("conditional_dialogues", [])
	if cond_list.is_empty():
		return data.get("dialogues", [])
	for cond in cond_list:
		if _eval_condition(cond.get("condition", ""), cond.get("threshold", 0)):
			if cond.has("choices"):
				data["_resolved_choices"] = cond["choices"]
			return cond.get("dialogues", [])
	return data.get("dialogues", [])

func _eval_condition(cond: String, threshold: int) -> bool:
	match cond:
		"trust_king_low": return GameState.trust_king < threshold
		"trust_king_high": return GameState.trust_king >= threshold
		"coup_route_active": return GameState.coup_route_active
		"coup_route_inactive": return not GameState.coup_route_active
		"voss_recruited": return GameState.voss_recruited
		"edric_recruited": return GameState.edric_recruited
	return false

func _get_visitor_choices() -> Array:
	if current_visitor_data.has("_resolved_choices"):
		var c = current_visitor_data["_resolved_choices"]
		current_visitor_data.erase("_resolved_choices")
		return c
	return current_visitor_data.get("choices", [])

# =============================================
# NIGHT EVENT
# =============================================
func _play_night_event() -> void:
	if GameState.current_day == 10:
		_handle_day10_crisis()
		return
	current_phase = Phase.NIGHT
	current_night_data = StoryLoader.get_night_event(GameState.current_day)
	if current_night_data.is_empty():
		_end_day()
		return
	phase_label.text = "🌙 Malam"
	narrator_label.text = current_night_data.get("narrator", "")
	var dialogs = current_night_data.get("dialogues", []).duplicate()
	for cond in current_night_data.get("conditional_dialogues", []):
		if _eval_condition(cond.get("condition",""), cond.get("threshold", 0)):
			dialogs += cond.get("dialogues", [])
	current_dialog_queue = dialogs
	dialog_index = 0
	choice_panel.visible = false
	king_response_panel.visible = false
	continue_btn.visible = true
	_show_next_dialog_in_queue()

# =============================================
# DAY 10 CRISIS
# =============================================
func _handle_day10_crisis() -> void:
	current_phase = Phase.CRISIS
	phase_label.text = "⚔ KRISIS HARI KE-10"
	var scenarios = day_data.get("crisis_scenarios", {})
	var scenario_key = GameState.get_day_10_crisis()
	var scenario = scenarios.get(scenario_key, {})
	if scenario.is_empty():
		_end_day()
		return
	narrator_label.text = scenario.get("narrator", "")
	current_visitor_data = scenario
	current_dialog_queue = scenario.get("dialogues", [])
	dialog_index = 0
	choice_panel.visible = false
	king_response_panel.visible = false
	continue_btn.visible = true
	_show_next_dialog_in_queue()

# =============================================
# DIALOG QUEUE
# =============================================
func _show_next_dialog_in_queue() -> void:
	if dialog_index >= current_dialog_queue.size():
		_on_dialogs_done()
		return
	var entry = current_dialog_queue[dialog_index]
	speaker_label.text = entry.get("speaker", "")
	dialog_label.text = entry.get("text", "")
	dialog_index += 1
	continue_btn.text = "Lanjutkan ▶"

func _on_continue_pressed() -> void:
	king_response_panel.visible = false
	_show_next_dialog_in_queue()

func _on_dialogs_done() -> void:
	match current_phase:
		Phase.MORNING: _next_visitor()
		Phase.VISITOR: _show_choices_for_visitor()
		Phase.NIGHT: _show_choices_for_night()
		Phase.CRISIS: _show_choices_for_crisis()
		Phase.TRANSITION: _advance_day()

# =============================================
# CHOICES
# =============================================
func _show_choices_for_visitor() -> void:
	var choices = _get_visitor_choices()
	if choices.is_empty():
		_advance_visitor()
		return
	_populate_choices(choices, _on_visitor_choice_selected)

func _show_choices_for_night() -> void:
	if current_night_data.get("is_ending", false):
		_end_day()
		return
	_populate_choices(current_night_data.get("choices", []), _on_night_choice_selected)

func _show_choices_for_crisis() -> void:
	_populate_choices(current_visitor_data.get("choices", []), _on_crisis_choice_selected)

func _populate_choices(choices: Array, callback: Callable) -> void:
	choice_panel.visible = true
	continue_btn.visible = false
	for child in choice_container.get_children():
		child.queue_free()
	for choice in choices:
		var btn = Button.new()
		btn.text = choice.get("text", "???")
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(func(): callback.call(choice))
		choice_container.add_child(btn)

func _on_visitor_choice_selected(choice: Dictionary) -> void:
	choice_panel.visible = false
	_process_choice(choice)
	continue_btn.text = "Pengunjung Selanjutnya ▶"
	continue_btn.pressed.disconnect_all_connected()
	continue_btn.pressed.connect(_advance_visitor)

func _on_night_choice_selected(choice: Dictionary) -> void:
	choice_panel.visible = false
	_process_choice(choice)
	_handle_coup_effect(choice)
	var ending_trigger = choice.get("ending_trigger", "")
	if not ending_trigger.is_empty():
		await get_tree().create_timer(2.0).timeout
		GameState.game_over.emit(ending_trigger)
		return
	continue_btn.text = "Akhiri Hari ▶"
	continue_btn.pressed.disconnect_all_connected()
	continue_btn.pressed.connect(_end_day)

func _on_crisis_choice_selected(choice: Dictionary) -> void:
	choice_panel.visible = false
	_process_choice(choice)
	var ending_trigger = choice.get("ending_trigger", "")
	if not ending_trigger.is_empty():
		await get_tree().create_timer(2.0).timeout
		GameState.game_over.emit(ending_trigger)
		return
	continue_btn.text = "Lanjutkan ▶"
	continue_btn.pressed.disconnect_all_connected()
	continue_btn.pressed.connect(_end_day)

func _process_choice(choice: Dictionary) -> void:
	var always_refuse = choice.get("always_refuse", false)
	var king_follows = (not always_refuse) and GameState.king_follows_advice()

	var applied_effects: Dictionary
	var king_text: String

	if king_follows:
		applied_effects = choice.get("effects", {})
		king_text = choice.get("king_follow_text", "")
	else:
		applied_effects = choice.get("king_refuse_effect", {})
		king_text = choice.get("king_refuse_text", "Raja membuat keputusannya sendiri.")

	var keshar_text = choice.get("keshar_text", "")
	if keshar_text != null and keshar_text != "":
		speaker_label.text = "Keshar"
		dialog_label.text = keshar_text

	king_response_label.text = "[b]Raja:[/b] " + king_text
	king_response_panel.visible = true

	GameState.apply_effects(applied_effects)

	var personality_shift = choice.get("personality_shift", "")
	if not personality_shift.is_empty():
		GameState._apply_personality_shift(personality_shift)

	_show_effect_popup(applied_effects)

	# Special flags
	var sf = choice.get("special_flag", "")
	match sf:
		"edric_recruited": GameState.edric_recruited = true
		"voss_recruited": GameState.voss_recruited = true
		"arvel_evidence": GameState.intel_level += 10

	var msg = choice.get("checkpoint_message", "")
	if not msg.is_empty():
		_show_checkpoint_popup(msg)

	continue_btn.visible = true

func _handle_coup_effect(choice: Dictionary) -> void:
	match choice.get("coup_effect", ""):
		"unlock": GameState.unlock_coup_route()
		"block": GameState.block_coup_route()
		"full_unlock":
			GameState.unlock_coup_route()
			GameState.military_support = max(GameState.military_support, 20)
		"strengthen":
			GameState.military_support = min(100, GameState.military_support + 15)
		"partial_block":
			if GameState.trust_king >= 60:
				GameState.block_coup_route()
		"progress":
			if GameState.coup_route_active:
				GameState.military_support = min(100, GameState.military_support + 5)
		"report":
			GameState.block_coup_route()

func _advance_visitor() -> void:
	current_visitor_index += 1
	king_response_panel.visible = false
	continue_btn.pressed.disconnect_all_connected()
	continue_btn.pressed.connect(_on_continue_pressed)
	_next_visitor()

# =============================================
# POPUPS
# =============================================
func _show_effect_popup(effects: Dictionary) -> void:
	if effects.is_empty(): return
	var labels = {
		"stability": "Stabilitas", "trust_king": "Kepercayaan Raja",
		"influence": "Pengaruh", "treasury": "Kas",
		"military": "Militer", "fear": "Rasa Takut",
		"military_support": "Dukungan Militer", "intel": "Intel"
	}
	var parts: Array[String] = []
	for key in labels:
		if effects.has(key) and effects[key] != 0:
			var val = effects[key]
			parts.append("%s %s%d" % [labels[key], ("+" if val > 0 else ""), val])
	if parts.is_empty(): return
	effect_popup.text = "\n".join(parts)
	effect_popup.modulate = Color(1, 1, 0.5)
	effect_popup.visible = true
	await get_tree().create_timer(2.0).timeout
	effect_popup.visible = false

func _show_checkpoint_popup(text: String) -> void:
	effect_popup.text = text
	effect_popup.modulate = Color(1, 0.4, 0.4)
	effect_popup.visible = true
	await get_tree().create_timer(3.0).timeout
	effect_popup.visible = false

# =============================================
# DAY MANAGEMENT
# =============================================
func _end_day() -> void:
	king_response_panel.visible = false
	continue_btn.pressed.disconnect_all_connected()
	continue_btn.pressed.connect(_on_continue_pressed)
	SaveManager.save_game()
	if GameState.current_day >= 10:
		var ending = GameState.check_final_ending()
		GameState.game_over.emit(ending)
		return
	GameState.current_day += 1
	_show_day_transition()

func _show_day_transition() -> void:
	current_phase = Phase.TRANSITION
	speaker_label.text = ""
	narrator_label.text = "[center]— Hari Berakhir —\n\n[b]Hari ke-%d[/b] akan dimulai..." % GameState.current_day
	dialog_label.text = ""
	choice_panel.visible = false
	king_response_panel.visible = false
	continue_btn.visible = true
	continue_btn.text = "▶ Mulai Hari %d" % GameState.current_day
	continue_btn.pressed.disconnect_all_connected()
	continue_btn.pressed.connect(_advance_day)

func _advance_day() -> void:
	continue_btn.pressed.disconnect_all_connected()
	continue_btn.pressed.connect(_on_continue_pressed)
	_start_day(GameState.current_day)

# =============================================
# STATS UI
# =============================================
func _on_stats_changed() -> void:
	_update_stats_ui()

func _update_stats_ui() -> void:
	stability_bar.value = GameState.stability
	trust_bar.value = GameState.trust_king
	influence_bar.value = GameState.influence
	treasury_bar.value = GameState.treasury
	military_bar.value = GameState.military
	fear_bar.value = GameState.fear
	stability_val.text = str(GameState.stability)
	trust_val.text = str(GameState.trust_king)
	influence_val.text = str(GameState.influence)
	treasury_val.text = str(GameState.treasury)
	military_val.text = str(GameState.military)
	fear_val.text = str(GameState.fear)

	var pers = GameState.king_personality
	if pers >= 20:
		king_personality_label.text = "Raja: Disiplin/Kuat (+%d)" % pers
		king_personality_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	elif pers <= -20:
		king_personality_label.text = "Raja: Impulsif/Paranoid (%d)" % pers
		king_personality_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	else:
		king_personality_label.text = "Raja: Netral (%d)" % pers
		king_personality_label.add_theme_color_override("font_color", Color(1, 1, 1))

	if GameState.coup_route_active:
		coup_indicator.text = "⚠ COUP | Pengaruh: %d | Mil: %d" % [GameState.influence, GameState.military_support]
		coup_indicator.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		coup_indicator.visible = true
	else:
		coup_indicator.visible = false

# =============================================
# GAME OVER
# =============================================
func _on_game_over(ending_id: String) -> void:
	SaveManager.delete_save()
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	var ending_scene = load("res://scenes/EndingScene.tscn")
	var instance = ending_scene.instantiate()
	instance.ending_id = ending_id
	get_tree().root.add_child(instance)
	queue_free()

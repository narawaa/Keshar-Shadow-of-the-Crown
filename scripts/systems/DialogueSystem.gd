extends Node

signal dialogue_finished

var dialog_queue: Array = []
var index := 0

var king_label: RichTextLabel
var keshar_label: RichTextLabel
var visitor_label: RichTextLabel

var typing := false
var typing_speed := 0.03

var _timer: Timer
var _active_label: RichTextLabel = null
var _full_text: String = ""

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = typing_speed
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timer_tick)
	add_child(_timer)

func setup(king: RichTextLabel, keshar: RichTextLabel, visitor: RichTextLabel) -> void:
	king_label    = king
	keshar_label  = keshar
	visitor_label = visitor

func start_dialogues(dialogs: Array) -> void:
	dialog_queue = dialogs
	index = 0
	_show_next()

func next() -> void:
	if typing:
		_timer.stop()
		if _active_label:
			_active_label.visible_characters = -1
		typing = false
		_active_label = null
		return
	_show_next()


# ======================================
func _show_next() -> void:
	if index >= dialog_queue.size():
		emit_signal("dialogue_finished")
		return

	var entry   = dialog_queue[index]
	index += 1

	var speaker: String = entry.get("speaker", "")
	var text: String    = entry.get("text", "")

	_clear_labels()

	var target: RichTextLabel
	match speaker:
		"Raja Aldric": target = king_label
		"Keshar":      target = keshar_label
		_:             target = visitor_label

	_start_typing(target, text)

func _start_typing(label: RichTextLabel, text: String) -> void:
	_active_label = label
	_full_text    = text

	label.text = text
	label.visible_characters = 0
	label.get_parent().get_parent().visible = true

	if text.is_empty():
		emit_signal("dialogue_finished")
		return

	typing = true
	_timer.wait_time = typing_speed
	_timer.start()

func _on_timer_tick() -> void:
	if _active_label == null:
		_timer.stop()
		typing = false
		return

	var cur   = _active_label.visible_characters
	var total = _full_text.length()

	if cur >= total:
		_timer.stop()
		typing = false
		_active_label = null
		return

	_active_label.visible_characters += 1

func _hide_bubble(label: RichTextLabel) -> void:
	label.text = ""
	label.visible_characters = 0
	label.get_parent().get_parent().visible = false

func _clear_labels() -> void:
	if king_label:    _hide_bubble(king_label)
	if keshar_label:  _hide_bubble(keshar_label)
	if visitor_label: _hide_bubble(visitor_label)

func force_stop():
	if _timer:
		_timer.stop()
	typing = false
	_active_label = null
	dialog_queue.clear()
	index = 0
	_clear_labels()

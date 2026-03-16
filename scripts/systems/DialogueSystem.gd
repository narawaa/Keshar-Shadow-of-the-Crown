extends Node

signal dialogue_finished

var dialog_queue : Array = []
var index := 0

var king_label
var keshar_label
var visitor_label

var typing := false
var typing_speed := 0.02

func setup(king, keshar, visitor):
	king_label = king
	keshar_label = keshar
	visitor_label = visitor

func start_dialogues(dialogs:Array):
	dialog_queue = dialogs
	index = 0
	_show_next()
	
func next():
	if typing:
		_finish_typing()
		return

	_show_next()

func _show_next():
	if index >= dialog_queue.size():
		emit_signal("dialogue_finished")
		return

	var entry = dialog_queue[index]
	index += 1

	var speaker = entry.get("speaker","")
	var text = entry.get("text","")

	_clear_labels()

	match speaker:
		"Raja Aldric":
			_type_text(king_label, text)
		"Keshar":
			_type_text(keshar_label, text)
		_:
			_type_text(visitor_label, text)

func _type_text(label:RichTextLabel,text:String):
	label.text = ""
	
	var bubble = label.get_parent().get_parent()
	bubble.visible = true

	typing = true
	for c in text:
		label.text += c
		await get_tree().create_timer(typing_speed).timeout

		if not typing:
			label.text = text
			return

	typing = false

func _finish_typing():
	typing = false
	
func _hide_bubble(label:RichTextLabel):
	label.text = ""
	label.get_parent().get_parent().visible = false
	
func _clear_labels():
	if king_label:
		_hide_bubble(king_label)
	if keshar_label:
		_hide_bubble(keshar_label)
	if visitor_label:
		_hide_bubble(visitor_label)

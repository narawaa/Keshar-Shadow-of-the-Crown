extends Node

var dialog_queue: Array = []
var index := 0

signal dialog_changed(speaker, text)
signal dialog_finished

func start(dialogs: Array):
	dialog_queue = dialogs
	index = 0
	next()

func next():
	if index >= dialog_queue.size():
		dialog_finished.emit()
		return
	
	var entry = dialog_queue[index]
	index += 1
	
	dialog_changed.emit(
		entry.get("speaker", ""),
		entry.get("text", "")
	)

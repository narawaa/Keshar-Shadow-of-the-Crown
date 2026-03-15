extends Node

signal choice_selected(choice)

func show_choices(container: VBoxContainer, choices: Array):
	
	for child in container.get_children():
		child.queue_free()
	
	for choice in choices:
		
		var btn = Button.new()
		btn.text = choice.get("text", "???")
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 50)
		
		btn.pressed.connect(func():
			choice_selected.emit(choice)
		)
		
		container.add_child(btn)

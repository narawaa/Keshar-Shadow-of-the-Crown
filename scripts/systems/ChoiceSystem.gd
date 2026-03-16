extends Node

signal choice_selected(choice)

var container

func setup(choice_container):
	container = choice_container

func show_choices(choices:Array):
	for c in container.get_children():
		c.queue_free()
		
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#2b2b2b")

	var focus_style = StyleBoxFlat.new()
	focus_style.bg_color = Color("#5a7cff")

	for choice in choices:
		var btn = Button.new()
		btn.text = choice.get("text","")
		
		btn.custom_minimum_size = Vector2(0,32)
		btn.add_theme_font_size_override("font_size", 16)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

		btn.focus_mode = Control.FOCUS_ALL
		
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("focus", focus_style)
		btn.add_theme_stylebox_override("hover", focus_style)
		
		btn.pressed.connect(func():
			print("CHOICE CLICKED")
			emit_signal("choice_selected", choice)
		)

		container.add_child(btn)
		
	if container.get_child_count() > 0:
		await get_tree().process_frame
		container.get_child(0).grab_focus()

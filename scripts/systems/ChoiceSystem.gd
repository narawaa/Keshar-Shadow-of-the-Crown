extends Node

signal choice_selected(choice)

var container: Control
var _locked := false

var normal_style 
var hover_style
var press_style

func setup(choice_container: Control) -> void:
	container = choice_container
	normal_style = _make_style(Color("#2f2115"), Color("#5a3e24"))
	hover_style  = _make_style(Color("#8b5e34"), Color("#d4a373"))
	press_style  = _make_style(Color("#1e1510"), Color("#d4a373"))

func show_choices(choices: Array) -> void:
	_locked = false
	_clear_buttons()

	for choice in choices:
		var btn = Button.new()
		btn.text = choice.get("text", "")
		btn.custom_minimum_size = Vector2(0, 100)
		btn.add_theme_font_size_override("font_size", 24)
		
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_ALL
		
		btn.add_theme_stylebox_override("normal",   normal_style)
		btn.add_theme_stylebox_override("focus",    hover_style)
		btn.add_theme_stylebox_override("hover",    hover_style)
		btn.add_theme_stylebox_override("pressed",  press_style)

		var captured = choice
		btn.pressed.connect(func():
			if _locked:
				return
			_locked = true
			_clear_buttons()
			emit_signal("choice_selected", captured)
		)
		container.add_child(btn)

	if container.get_child_count() > 0:
		await get_tree().process_frame
		if container.get_child_count() > 0:
			container.get_child(0).grab_focus()

func clear() -> void:
	_clear_buttons()


# ======================================
func _clear_buttons() -> void:
	if not container:
		return
		
	for c in container.get_children():
		c.queue_free()

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(8)
	s.border_width_left   = 3
	s.border_width_right  = 3
	s.border_width_top    = 3
	s.border_width_bottom = 3
	s.border_color = border
	s.content_margin_left   = 16
	s.content_margin_right  = 16
	s.content_margin_top    = 16
	s.content_margin_bottom = 16
	return s

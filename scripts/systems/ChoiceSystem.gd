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

	var btn_index := 0
	for choice in choices:
		var btn = Button.new()
		btn.text = choice.get("text", "")
		btn.custom_minimum_size = Vector2(0, 100)
		btn.add_theme_font_size_override("font_size", 24)

		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_ALL

		btn.add_theme_stylebox_override("normal",  normal_style)
		btn.add_theme_stylebox_override("focus",   hover_style)
		btn.add_theme_stylebox_override("hover",   hover_style)
		btn.add_theme_stylebox_override("pressed", press_style)

		btn.modulate.a = 0.0
		btn.position.x -= 40.0

		var captured = choice
		var captured_btn = btn
		btn.mouse_entered.connect(func():
			if not _locked:
				var tw = captured_btn.create_tween()
				tw.tween_property(captured_btn, "scale", Vector2(1.03, 1.03), 0.1).set_ease(Tween.EASE_OUT)
		)
		btn.mouse_exited.connect(func():
			var tw = captured_btn.create_tween()
			tw.tween_property(captured_btn, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT)
		)
		btn.pressed.connect(func():
			if _locked:
				return
			_locked = true
			var tw = captured_btn.create_tween()
			tw.tween_property(captured_btn, "scale", Vector2(0.96, 0.96), 0.08)
			await tw.finished
			_dismiss_buttons()
			emit_signal("choice_selected", captured)
		)
		container.add_child(btn)

		var delay = btn_index * 0.08
		var tw = btn.create_tween()
		tw.tween_interval(delay)
		tw.set_parallel(false)
		tw.tween_property(btn, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)

		var target_x = btn.position.x + 40.0
		btn.position.x = btn.position.x  # already offset
		var tw2 = btn.create_tween()
		tw2.tween_interval(delay)
		tw2.tween_property(btn, "position:x", target_x, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

		btn_index += 1

	if container.get_child_count() > 0:
		await get_tree().process_frame
		if container.get_child_count() > 0:
			container.get_child(0).grab_focus()

func _dismiss_buttons() -> void:
	for c in container.get_children():
		var tw = c.create_tween()
		tw.set_parallel(true)
		tw.tween_property(c, "modulate:a", 0.0, 0.15)
		tw.tween_property(c, "position:x", c.position.x - 30.0, 0.15).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.18).timeout
	_clear_buttons()

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

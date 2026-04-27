extends PanelContainer

@onready var label = $HBoxContainer/Val

const DURATION   := 2.5
const SLIDE_DIST := 80.0

func show_stat(text: String, status: String) -> void:
	label.text = text
	var color: String
	if status == "header":
		color = "#ffffff"
	elif status == "positive":
		color = "#7fff7f"
	else:
		color = "#ff7f7f"
	label.add_theme_color_override("font_color", Color(color))

	await get_tree().process_frame

	var target_x = position.x
	position.x += SLIDE_DIST
	modulate.a  = 0.0

	var tw_in = create_tween().set_parallel(true)
	tw_in.tween_property(self, "modulate:a", 1.0, 0.25)
	tw_in.tween_property(self, "position:x", target_x, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	await get_tree().create_timer(DURATION).timeout

	var tw_out = create_tween().set_parallel(true)
	tw_out.tween_property(self, "modulate:a", 0.0, 0.3)
	tw_out.tween_property(self, "position:x", target_x + SLIDE_DIST * 0.4, 0.3)
	await tw_out.finished

	queue_free()

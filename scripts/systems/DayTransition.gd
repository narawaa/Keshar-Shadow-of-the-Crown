extends CanvasLayer

signal transition_finished
signal next_day_pressed

@onready var overlay:      ColorRect = $Overlay
@onready var day_label:    Label     = $CenterContainer/VBox/DayLabel
@onready var title_label:  Label     = $CenterContainer/VBox/TitleLabel
@onready var next_btn:     Button    = $CenterContainer/VBox/NextButton
@onready var center:       Control   = $CenterContainer

const DAY_NAMES = {
	1: "PERTAMA",   2: "KEDUA",      3: "KETIGA",
	4: "KEEMPAT",   5: "KELIMA",     6: "KEENAM",
	7: "KETUJUH",   8: "KEDELAPAN",  9: "KESEMBILAN",
	10: "KESEPULUH"
}

func _ready() -> void:
	visible = false
	next_btn.visible = false

func play(day: int, day_title: String = "") -> void:
	var day_name = DAY_NAMES.get(day, "KE-%d" % day)
	_reset_ui()
	
	center.modulate.a = 0.0
	overlay.modulate.a = 0.0
	visible = true

	var tw_fade = create_tween()
	tw_fade.tween_property(overlay, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	await tw_fade.finished

	var tw_text = create_tween()
	tw_text.tween_property(center, "modulate:a", 1.0, 0.4)
	await tw_text.finished

	await _type_label(day_label, "HARI " + day_name, 0.07)
	await get_tree().create_timer(0.3).timeout

	if day_title != "":
		await _type_label(title_label, day_title, 0.04)

	await get_tree().create_timer(1.0).timeout

	next_btn.modulate.a = 0.0
	next_btn.visible = true
	var tw_btn = create_tween()
	tw_btn.tween_property(next_btn, "modulate:a", 1.0, 0.3)
	await tw_btn.finished

	next_btn.grab_focus()
	emit_signal("transition_finished")

func hide_transition() -> void:
	var tw = create_tween().set_parallel(true)

	# fade overlay + content barengan
	tw.tween_property(center, "modulate:a", 0.0, 0.25).set_delay(0.05)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.4)

	await tw.finished

	visible = false
	overlay.modulate.a = 0.0
	center.modulate.a = 0.0
	_reset_ui()


# ======================================
func _reset_ui() -> void:
	day_label.text   = ""
	title_label.text = ""
	next_btn.visible = false

func _type_label(lbl: Label, text: String, speed: float) -> void:
	lbl.text = ""
	for ch in text:
		lbl.text += ch
		await get_tree().create_timer(speed).timeout

func _on_next_button_pressed() -> void:
	next_btn.visible = false
	emit_signal("next_day_pressed")

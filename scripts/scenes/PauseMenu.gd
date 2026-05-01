extends Control

signal resume_pressed
signal exit_pressed

@onready var panel = $Panel

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	panel.modulate.a = 0.0

# ========================
# OPEN / CLOSE
func open():
	visible = true
	_fade_in()
	$Panel/MarginContainer/VBoxContainer/ExitButton.grab_focus()

func close():
	await _fade_out()
	visible = false


# ========================
# ANIMATION
func _fade_in():
	panel.modulate.a = 0.0
	
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)

func _fade_out():
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "modulate:a", 0.0, 0.2)
	await tw.finished


# ========================
# BUTTONS
func _on_resume_button_pressed():
	resume_pressed.emit()

func _on_exit_button_pressed():
	exit_pressed.emit()

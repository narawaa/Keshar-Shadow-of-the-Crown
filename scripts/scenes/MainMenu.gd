extends Control

# =============================================
# MainMenu.gd
# Menu utama: mulai baru, lanjutkan, keluar
# =============================================

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var start_btn: Button = $VBoxContainer/ButtonContainer/StartButton
@onready var continue_btn: Button = $VBoxContainer/ButtonContainer/ContinueButton
@onready var quit_btn: Button = $VBoxContainer/ButtonContainer/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# Cek apakah ada save file
	var has_save = SaveManager.has_save()
	continue_btn.disabled = not has_save
	
	version_label.text = "v0.1 — Prototype"
	
	# Animasi
	modulate = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.0)

func _on_start_pressed() -> void:
	GameState.reset()
	SaveManager.delete_save()
	_go_to_game()

func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
		_go_to_game()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _go_to_game() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/gameplay/GameScene.tscn")

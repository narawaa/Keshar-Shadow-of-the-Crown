extends Node

# =============================================
# SaveManager.gd — Autoload
# Mengelola simpan dan muat game
# =============================================

const SAVE_PATH = "user://solo_save.json"

func save_game() -> void:
	var data = GameState.get_save_data()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Tidak bisa membuka file untuk save")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Game disimpan: Hari ", data.get("current_day", 0))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("SaveManager: Error parsing save file")
		return false
	
	GameState.load_save_data(json.get_data())
	print("Game dimuat: Hari ", GameState.current_day)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

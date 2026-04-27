extends Node

const SAVE_PATH = "user://solo_save.json"

func save_game() -> void:
	var data = GameState.get_save_data()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Gagal save ke " + SAVE_PATH)
		return
		
	file.store_string(JSON.stringify(data))
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
	if json.parse(json_string) != OK or typeof(json.get_data()) != TYPE_DICTIONARY:
		push_error("SaveManager: Gagal menyimpan file")
		return false
	
	GameState.load_save_data(json.get_data())
	
	print("Game dimuat: Hari ", GameState.current_day)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

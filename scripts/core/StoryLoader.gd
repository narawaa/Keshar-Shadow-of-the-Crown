extends Node

# =============================================
# StoryLoader.gd — Autoload
# Memuat dan parse file JSON cerita per hari
# =============================================

var _cache: Dictionary = {}

func load_day(day_number: int) -> Dictionary:
	var key = "day_%d" % day_number
	if _cache.has(key):
		return _cache[key]
	
	var path = "res://data/story_day%d.json" % day_number
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("StoryLoader: Tidak bisa buka file %s" % path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("StoryLoader: Parse error di %s: %s" % [path, json.get_error_message()])
		return {}
	
	var data = json.get_data()
	_cache[key] = data
	return data

func get_visitor(day: int, visitor_index: int) -> Dictionary:
	var day_data = load_day(day)
	if day_data.is_empty():
		return {}
	var visitors = day_data.get("visitors", [])
	if visitor_index >= visitors.size():
		return {}
	return visitors[visitor_index]

func get_night_event(day: int) -> Dictionary:
	var day_data = load_day(day)
	return day_data.get("night_event", {})

func get_morning_briefing(day: int) -> Dictionary:
	var day_data = load_day(day)
	return day_data.get("morning_briefing", {})

func get_visitor_count(day: int) -> int:
	var day_data = load_day(day)
	return day_data.get("visitors", []).size()

func get_day_title(day: int) -> String:
	var day_data = load_day(day)
	return day_data.get("title", "Hari %d" % day)

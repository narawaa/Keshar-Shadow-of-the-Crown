extends Node

var container: Control
var toast_scene = preload("res://scenes/menus/StatToast.tscn")

const STAT_LABELS = {
	"stability":        "Stabilitas Negara",
	"trust_king":       "Kepercayaan Raja",
	"influence":        "Pengaruh Keshar",
	"treasury":         "Kas Negara",
	"military":         "Militer Negara",
}

func setup(c: Control) -> void:
	container = c

func show_effects(effects: Dictionary, king_followed: bool) -> void:
	if effects.is_empty():
		return

	var header = "RAJA MENERIMA NASIHAT" if king_followed else "RAJA MENOLAK NASIHAT"
	_spawn_toast(header, "header")

	for key in effects:
		if not STAT_LABELS.has(key):
			continue
			
		if effects.has(key) and effects[key] != 0:
			var val  = effects[key]
			var sign = "+" if val > 0 else ""
			var text = "%s %s%d" % [STAT_LABELS[key], sign, val]
			_spawn_toast(text, 
				"positive" if val > 0 else "negative")


# ======================================
func _spawn_toast(text: String, status: String) -> void:
	var toast = toast_scene.instantiate()
	container.add_child(toast)
	toast.show_stat(text, status)

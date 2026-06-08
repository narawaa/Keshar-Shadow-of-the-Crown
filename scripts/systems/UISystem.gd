extends Node

var day_label: Label
var stability_label: Label
var trust_label: Label
var treasury_label: Label
var military_label: Label
var influence_label: Label

var _defer_stats: bool = false
var _prev_stats: Dictionary = {}

func setup(day_lbl: Label) -> void:
	day_label   = day_lbl

func setup_stats(
	stability: Label, trust: Label,
	treasury: Label,  military: Label,
	influence: Label
) -> void:
	stability_label = stability
	trust_label     = trust
	treasury_label  = treasury
	military_label  = military
	influence_label = influence

	GameState.stats_changed.connect(_on_stats_changed)
	update_stats()

func set_day(day: int, title: String) -> void:
	day_label.text = "Hari %d" % [day]

# SEBELUM dialog raja, stats tidak berubah di ui sampai commit dipanggil
func begin_deferred_stats() -> void:
	_defer_stats = true

# SETELAH dialog raja selesai, baru apply effects dan update UI
func commit_deferred_stats() -> void:
	_defer_stats = false
	GameState.apply_staged_effects()

func _flash_stat(label: Label, increased: bool) -> void:
	var container = label.get_parent()
	var color = Color(0.3, 1.0, 0.45, 1.0) if increased else Color(1.0, 0.3, 0.3, 1.0)
	var tw = container.create_tween()
	tw.tween_property(container, "modulate", color, 0.1)
	tw.tween_property(container, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.9)

func _maybe_flash(label: Label, key: String, new_val: int) -> void:
	if label == null:
		return
	var old_val: int = _prev_stats.get(key, new_val)
	if new_val > old_val:
		_flash_stat(label, true)
	elif new_val < old_val:
		_flash_stat(label, false)

func update_stats() -> void:
	_maybe_flash(stability_label, "stability",  GameState.stability)
	_maybe_flash(trust_label,     "trust_king", GameState.trust_king)
	_maybe_flash(treasury_label,  "treasury",   GameState.treasury)
	_maybe_flash(military_label,  "military",   GameState.military)
	_maybe_flash(influence_label, "influence",  GameState.influence)

	if stability_label: stability_label.text = str(GameState.stability)
	if trust_label:     trust_label.text     = str(GameState.trust_king)
	if treasury_label:  treasury_label.text  = str(GameState.treasury)
	if military_label:  military_label.text  = str(GameState.military)
	if influence_label: influence_label.text = str(GameState.influence)

	_prev_stats["stability"]  = GameState.stability
	_prev_stats["trust_king"] = GameState.trust_king
	_prev_stats["treasury"]   = GameState.treasury
	_prev_stats["military"]   = GameState.military
	_prev_stats["influence"]  = GameState.influence

# ======================================
func _on_stats_changed() -> void:
	if _defer_stats:
		return
	update_stats()

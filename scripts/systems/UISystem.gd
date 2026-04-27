extends Node

var day_label: Label
var stability_label: Label
var trust_label: Label
var treasury_label: Label
var military_label: Label
var influence_label: Label

var _defer_stats: bool = false

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

func update_stats() -> void:
	if stability_label: stability_label.text = str(GameState.stability)
	if trust_label:     trust_label.text     = str(GameState.trust_king)
	if treasury_label:  treasury_label.text  = str(GameState.treasury)
	if military_label:  military_label.text  = str(GameState.military)
	if influence_label: influence_label.text = str(GameState.influence)

# ======================================
func _on_stats_changed() -> void:
	if _defer_stats:
		return
	update_stats()

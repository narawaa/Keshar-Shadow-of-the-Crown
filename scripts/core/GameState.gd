extends Node

signal stats_changed
signal coup_route_changed(is_active: bool)
signal game_over(ending_id: String)

# --- STATS (0-100 kecuali king_personality) ---
var stability: int = 50
var trust_king: int = 30
var influence: int = 20
var treasury: int = 60
var military: int = 50

# -50 (Paranoid) hingga +50 (Strong)
var king_personality: int = 0

var current_day: int = 1
var coup_route_active: bool = false
var coup_route_blocked: bool = false
var coup_conspirators: Array[String] = []
var edric_recruited: bool = false
var voss_recruited: bool = false
var king_state: String = "neutral"
var intel_level: int = 0
var queen_knows: bool = false

# =============================================
# FORMULA RAJA IKUT SARAN
# Target: ~70% nurut di kondisi awal (trust=30, pers=0)
#
# Cara kerja:
#   roll = randi_range(1, 100)  ← angka acak 1-100
#   threshold = base - trust_bonus - pers_bonus
#   nurut jika roll > threshold
#
# Final formula:
#   threshold = 50 - int(trust_king * 0.667) - int(king_personality * 0.3)
#   trust=30, pers=0  → 50 - 20 - 0 = 30 → nurut jika roll > 30 = 70% ✓
#   trust=50, pers=0  → 50 - 33 - 0 = 17 → nurut jika roll > 17 = 83%
#   trust=70, pers=10 → 50 - 47 - 3  = 0  → nurut jika roll > 0  = 100%
#   trust=10, pers=0  → 50 - 7  - 0  = 43 → nurut jika roll > 43 = 57%
# =============================================
func king_follows_advice() -> bool:
	var threshold = 50 - int(trust_king * 0.667) - int(king_personality * 0.3)
	threshold = clamp(threshold, 0, 95)  # max tolak 95%, min selalu nurut
	var roll = randi_range(1, 100)
	return roll > threshold


# ======================================
# DEFERRED EFFECTS, stage dulu → apply setelah dialog raja selesai
var _staged_effects: Dictionary = {}
var _staged_king_followed: bool = false

func stage_effects(effects: Dictionary, king_followed: bool) -> void:
	_staged_effects = effects.duplicate()
	_staged_king_followed = king_followed

func apply_staged_effects() -> void:
	apply_effects(_staged_effects)
	_staged_effects = {}

func get_staged_effects() -> Dictionary:
	return _staged_effects

func get_staged_king_followed() -> bool:
	return _staged_king_followed


# ======================================
# APPLY EFFECTS
func apply_effects(effects: Dictionary) -> void:
	if effects.has("stability"):
		stability = clamp(stability + effects["stability"], 0, 100)
	if effects.has("trust_king"):
		trust_king = clamp(trust_king + effects["trust_king"], 0, 100)
	if effects.has("influence"):
		influence = clamp(influence + effects["influence"], 0, 100)
	if effects.has("treasury"):
		treasury = clamp(treasury + effects["treasury"], 0, 100)
	if effects.has("military"):
		military = clamp(military + effects["military"], 0, 100)
	if effects.has("king_personality"):
		king_personality = clamp(king_personality + effects["king_personality"], -50, 50)
	if effects.has("intel"):
		intel_level = clamp(intel_level + effects["intel"], 0, 100)
	if effects.has("personality_shift"):
		_apply_personality_shift(effects["personality_shift"])

	emit_signal("stats_changed")
	_check_end_conditions()

func _apply_personality_shift(shift: String) -> void:
	match shift:
		"strong":    king_state = "strong"
		"dependent": king_state = "dependent"
		"paranoid":  king_state = "paranoid"


# ======================================
# COUP ROUTE
func unlock_coup_route() -> void:
	if not coup_route_blocked:
		coup_route_active = true
		emit_signal("coup_route_changed", true)

func block_coup_route() -> void:
	coup_route_blocked = true
	coup_route_active = false
	emit_signal("coup_route_changed", false)

func recruit_conspirator(name: String) -> void:
	if not coup_conspirators.has(name):
		coup_conspirators.append(name)


# ======================================
# END CONDITIONS
func _check_end_conditions() -> void:
	if stability <= 0:
		emit_signal("game_over", "ending_4_collapse")
		return
	if treasury <= 0 and current_day >= 5:
		emit_signal("game_over", "ending_4_collapse")
		return

func check_final_ending() -> String:
	if influence > 70 and trust_king < 30 and military > 50:
		return "ending_1_keshar_raja"
	elif coup_route_active and influence < 50:
		return "ending_2_coup_gagal"
	elif trust_king >= 60 and stability > 50:
		return "ending_3_raja_berkembang"
	else:
		return "ending_4_collapse"

func get_day_10_crisis() -> String:
	if stability < 30:
		return "pemberontakan"
	elif military < 30:
		return "invasi"
	elif coup_route_active and influence > 70:
		return "kudeta"
	else:
		return "pemberontakan"


# ======================================
# SAVE / LOAD / RESET
func get_save_data() -> Dictionary:
	return {
		"stability": stability, "trust_king": trust_king,
		"influence": influence, "treasury": treasury,
		"military": military, "king_personality": king_personality,
		"current_day": current_day, "coup_route_active": coup_route_active,
		"coup_route_blocked": coup_route_blocked, "king_state": king_state,
		"intel_level": intel_level, "queen_knows": queen_knows,
		"edric_recruited": edric_recruited, "voss_recruited": voss_recruited,
	}

func load_save_data(data: Dictionary) -> void:
	stability      = data.get("stability", 50)
	trust_king     = data.get("trust_king", 30)
	influence      = data.get("influence", 20)
	treasury       = data.get("treasury", 60)
	military       = data.get("military", 50)
	king_personality = data.get("king_personality", 0)
	current_day    = data.get("current_day", 1)
	coup_route_active   = data.get("coup_route_active", false)
	coup_route_blocked  = data.get("coup_route_blocked", false)
	king_state     = data.get("king_state", "neutral")
	intel_level    = data.get("intel_level", 0)
	queen_knows    = data.get("queen_knows", false)
	edric_recruited = data.get("edric_recruited", false)
	voss_recruited  = data.get("voss_recruited", false)
	emit_signal("stats_changed")

func reset() -> void:
	stability = 50;  trust_king = 30;  influence = 20
	treasury = 60;   military = 50;  king_personality = 0
	current_day = 1
	coup_route_active = false;  coup_route_blocked = false
	coup_conspirators = [];     king_state = "neutral"
	intel_level = 0;  queen_knows = false
	edric_recruited = false;  voss_recruited = false
	_staged_effects = {}
	_staged_king_followed = false
	emit_signal("stats_changed")

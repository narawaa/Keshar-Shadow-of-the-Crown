extends Node

# =============================================
# GameState.gd — Autoload / Singleton
# Menyimpan semua statistik kerajaan dan state permainan
# =============================================

signal stats_changed
signal coup_route_changed(is_active: bool)
signal game_over(ending_id: String)

# --- STATS UTAMA (semua 0-100 kecuali king_personality) ---
var stability: int = 50
var trust_king: int = 30
var influence: int = 20
var treasury: int = 60
var military: int = 50
var fear: int = 10
var military_support: int = 0  # Support militer untuk kudeta

# King Personality: -50 (Impulsive/Paranoid) hingga +50 (Disciplined/Strong)
var king_personality: int = 0

# --- FLAGS CERITA ---
var current_day: int = 1
var coup_route_active: bool = false
var coup_route_blocked: bool = false
var coup_conspirators: Array[String] = []  # nama yang sudah direkrut
var edric_recruited: bool = false
var voss_recruited: bool = false

# Tracking personality raja
var king_state: String = "neutral"  # "neutral", "strong", "dependent", "paranoid"

# Intel yang dikumpulkan
var intel_level: int = 0

# Apakah permaisuri tahu rencana Keshar
var queen_knows: bool = false

# --- FORMULA RAJA MENGIKUTI SARAN ---
func calculate_king_follow_chance() -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var chance = int(trust_king * 0.5) + int(king_personality * 0.3) + rng.randi_range(0, 20)
	return chance

func king_follows_advice() -> bool:
	return calculate_king_follow_chance() >= 50

# --- APPLY EFFECTS dari pilihan ---
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
	if effects.has("fear"):
		fear = clamp(fear + effects["fear"], 0, 100)
	if effects.has("military_support"):
		military_support = clamp(military_support + effects["military_support"], 0, 100)
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
		"strong":
			king_state = "strong"
		"dependent":
			king_state = "dependent"
		"paranoid":
			king_state = "paranoid"

# --- COUP ROUTE MANAGEMENT ---
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

# --- KONDISI AKHIR PERMAINAN ---
func _check_end_conditions() -> void:
	# Cek kalah karena stabilitas nol
	if stability <= 0:
		emit_signal("game_over", "ending_4_collapse")
		return
	
	# Cek kalah karena kas habis
	if treasury <= 0 and current_day >= 5:
		emit_signal("game_over", "ending_4_collapse")
		return

func check_final_ending() -> String:
	# Cek ending berdasarkan kondisi akhir game
	if influence > 70 and trust_king < 30 and military_support > 50:
		return "ending_1_keshar_raja"
	elif coup_route_active and influence < 50:
		return "ending_2_coup_gagal"
	elif trust_king >= 60 and stability > 50:
		return "ending_3_raja_berkembang"
	else:
		return "ending_4_collapse"

func get_day_10_crisis() -> String:
	# Tentukan skenario krisis di hari 10
	if stability < 30:
		return "pemberontakan"
	elif military < 30:
		return "invasi"
	elif coup_route_active and influence > 70:
		return "kudeta"
	else:
		return "pemberontakan"  # default

# --- SAVE / LOAD ---
func get_save_data() -> Dictionary:
	return {
		"stability": stability,
		"trust_king": trust_king,
		"influence": influence,
		"treasury": treasury,
		"military": military,
		"fear": fear,
		"military_support": military_support,
		"king_personality": king_personality,
		"current_day": current_day,
		"coup_route_active": coup_route_active,
		"coup_route_blocked": coup_route_blocked,
		"king_state": king_state,
		"intel_level": intel_level,
		"queen_knows": queen_knows,
		"edric_recruited": edric_recruited,
		"voss_recruited": voss_recruited,
	}

func load_save_data(data: Dictionary) -> void:
	stability = data.get("stability", 50)
	trust_king = data.get("trust_king", 30)
	influence = data.get("influence", 20)
	treasury = data.get("treasury", 60)
	military = data.get("military", 50)
	fear = data.get("fear", 10)
	military_support = data.get("military_support", 0)
	king_personality = data.get("king_personality", 0)
	current_day = data.get("current_day", 1)
	coup_route_active = data.get("coup_route_active", false)
	coup_route_blocked = data.get("coup_route_blocked", false)
	king_state = data.get("king_state", "neutral")
	intel_level = data.get("intel_level", 0)
	queen_knows = data.get("queen_knows", false)
	edric_recruited = data.get("edric_recruited", false)
	voss_recruited = data.get("voss_recruited", false)
	emit_signal("stats_changed")

func reset() -> void:
	stability = 50
	trust_king = 30
	influence = 20
	treasury = 60
	military = 50
	fear = 10
	military_support = 0
	king_personality = 0
	current_day = 1
	coup_route_active = false
	coup_route_blocked = false
	coup_conspirators = []
	king_state = "neutral"
	intel_level = 0
	queen_knows = false
	edric_recruited = false
	voss_recruited = false
	emit_signal("stats_changed")

extends Control

# =============================================
# EndingScene.gd
# Menampilkan salah satu dari 4 ending
# =============================================

var ending_id: String = "ending_3_raja_berkembang"

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var ending_label: Label = $VBoxContainer/EndingTitleLabel
@onready var description_label: RichTextLabel = $VBoxContainer/DescriptionLabel
@onready var stats_summary: RichTextLabel = $VBoxContainer/StatsSummary
@onready var main_menu_btn: Button = $VBoxContainer/ButtonRow/MainMenuButton
@onready var play_again_btn: Button = $VBoxContainer/ButtonRow/PlayAgainButton

const ENDINGS = {
	"ending_1_keshar_raja": {
		"title": "ENDING 1",
		"subtitle": "Keshar Menjadi Raja",
		"color": Color(0.8, 0.2, 0.2),
		"description": "Keshar duduk di singgasana. Tenang. Ini bukan kemenangan yang terasa manis.\n\nDi sudut matanya, terbayang wajah raja muda yang pernah berkata 'aku tidak bisa membayangkan memimpin tanpamu, Keshar'.\n\nTapi kerajaan ini kini stabil. Utang darah ada. Tapi stabilitas juga ada.\n\n[i]Pertanyaannya bukan apakah kamu menang — tapi apakah kemenangan ini layak kamu sebut kemenangan.[/i]",
		"requirements": "Pengaruh > 70 | Kepercayaan Raja < 30 | Dukungan Militer > 50"
	},
	"ending_2_coup_gagal": {
		"title": "ENDING 2",
		"subtitle": "Kudeta Gagal",
		"color": Color(0.6, 0.1, 0.1),
		"description": "Keshar berdiri di hadapan raja yang kini tidak lagi remaja. Tidak ada belas kasihan di matanya.\n\nIni konsekuensi dari setiap pilihan yang salah. Keshar dituntun ke luar ruang tahta untuk terakhir kalinya.\n\n[i]Ambisi tanpa kebijaksanaan hanya meninggalkan rantai.[/i]",
		"requirements": "Coup Route Aktif | Pengaruh Rendah atau Raja Berhasil Menghentikan Kudeta"
	},
	"ending_3_raja_berkembang": {
		"title": "ENDING 3",
		"subtitle": "Raja Berkembang",
		"color": Color(0.2, 0.7, 0.3),
		"description": "Setahun kemudian. Raja Aldric berdiri di depan rakyatnya, berbicara dengan keyakinan yang tidak ada sebulan lalu.\n\nDi sampingnya, Keshar — bukan sebagai arsitek bayangan, tapi sebagai penasihat yang benar-benar melayani.\n\nMungkin ini cara terbaik cerita ini berakhir.\n\n[i]Mungkin.[/i]",
		"requirements": "Kepercayaan Raja Tinggi | Stabilitas > 70 | Keshar Memilih Loyalitas di Akhir"
	},
	"ending_4_collapse": {
		"title": "ENDING 4",
		"subtitle": "Kerajaan Runtuh",
		"color": Color(0.4, 0.4, 0.4),
		"description": "Istana terbakar. Rakyat mengungsi. Kerajaan yang pernah berdiri megah kini menjadi abu.\n\nTidak ada pemenang. Hanya pelajaran yang terlambat dipetik — dan dua orang yang sama-sama gagal menjaga apa yang seharusnya mereka jaga bersama.\n\n[i]Beberapa kisah tidak berakhir dengan kemenangan — hanya penyesalan.[/i]",
		"requirements": "Stabilitas < 20 di Akhir Krisis"
	}
}

func _ready() -> void:
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	play_again_btn.pressed.connect(_on_play_again_pressed)
	
	_display_ending()
	
	# Fade in
	modulate = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.5)

func _display_ending() -> void:
	var ending_data = ENDINGS.get(ending_id, ENDINGS["ending_4_collapse"])
	
	title_label.text = ending_data["title"]
	ending_label.text = ending_data["subtitle"]
	ending_label.add_theme_color_override("font_color", ending_data["color"])
	description_label.text = ending_data["description"]
	
	# Tampilkan statistik akhir
	var stats_text = """[b]Statistik Akhir:[/b]
	
Stabilitas: %d
Kepercayaan Raja: %d
Pengaruh: %d
Kas Kerajaan: %d
Militer: %d
Rasa Takut Rakyat: %d
Hari Berhasil Dilalui: %d

Kepribadian Raja: %s
Coup Route: %s""" % [
		GameState.stability,
		GameState.trust_king,
		GameState.influence,
		GameState.treasury,
		GameState.military,
		GameState.fear,
		GameState.current_day,
		_get_king_personality_text(),
		"Aktif" if GameState.coup_route_active else "Tidak Aktif"
	]
	
	stats_summary.text = stats_text

func _get_king_personality_text() -> String:
	var p = GameState.king_personality
	if p >= 20: return "Disiplin/Kuat"
	if p <= -20: return "Impulsif/Paranoid"
	return "Netral"

func _on_main_menu_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_play_again_pressed() -> void:
	GameState.reset()
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

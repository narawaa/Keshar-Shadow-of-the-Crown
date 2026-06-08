extends Node

signal dialogue_finished

var dialog_queue: Array = []
var index := 0

var king_label: RichTextLabel
var keshar_label: RichTextLabel
var visitor_label: RichTextLabel

var king_sprite: Node2D
var keshar_sprite: Node2D
var visitor_sprite: Node2D

var typing := false
var typing_speed := 0.03

var _timer: Timer
var _active_label: RichTextLabel = null
var _full_text: String = ""

# Talking animation state
var _talk_tween: Tween = null
var _active_sprite: Node2D = null
var _modulate_tweens: Dictionary = {}
var _king_base_scale: Vector2
var _keshar_base_scale: Vector2
var _visitor_base_scale: Vector2

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = typing_speed
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timer_tick)
	add_child(_timer)

func setup(king: RichTextLabel, keshar: RichTextLabel, visitor: RichTextLabel) -> void:
	king_label    = king
	keshar_label  = keshar
	visitor_label = visitor

func setup_sprites(king: Node2D, keshar: Node2D, visitor: Node2D) -> void:
	king_sprite    = king
	keshar_sprite  = keshar
	visitor_sprite = visitor

	if king_sprite:
		_king_base_scale    = king_sprite.scale
	if keshar_sprite:
		_keshar_base_scale  = keshar_sprite.scale
	if visitor_sprite:
		_visitor_base_scale = visitor_sprite.scale

func start_dialogues(dialogs: Array) -> void:
	dialog_queue = dialogs.duplicate()  # ← duplicate() bukan assign langsung
	index = 0
	_show_next()

func next() -> void:
	if typing:
		_timer.stop()
		if _active_label:
			_active_label.visible_characters = -1
		typing = false
		_active_label = null
		_stop_talking_anim()
		return
	_show_next()


# ======================================
func _show_next() -> void:
	if index >= dialog_queue.size():
		_stop_talking_anim()
		call_deferred("emit_signal", "dialogue_finished")
		return

	var entry   = dialog_queue[index]
	index += 1

	var speaker: String = entry.get("speaker", "")
	var text: String    = entry.get("text", "")

	_clear_labels()

	var target: RichTextLabel
	var target_sprite: Node2D
	match speaker:
		"Raja Aldric":
			target        = king_label
			target_sprite = king_sprite
		"Keshar":
			target        = keshar_label
			target_sprite = keshar_sprite
		_:
			target        = visitor_label
			target_sprite = visitor_sprite

	_start_talking_anim(target_sprite)
	_start_typing(target, text)

func _start_typing(label: RichTextLabel, text: String) -> void:
	_active_label = label
	_full_text    = text

	label.text = text
	label.visible_characters = 0

	# Pop in the bubble
	var bubble = label.get_parent().get_parent()
	bubble.visible = true
	bubble.scale = Vector2(0.5, 0.5)
	bubble.modulate.a = 0.0

	var tw = bubble.create_tween()
	tw.set_parallel(true)
	tw.tween_property(bubble, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bubble, "modulate:a", 1.0, 0.15)

	_update_dim_by_bubble()

	if text.is_empty():
		call_deferred("emit_signal", "dialogue_finished")
		return

	typing = true
	_timer.wait_time = typing_speed
	_timer.start()

func _on_timer_tick() -> void:
	if _active_label == null:
		_timer.stop()
		typing = false
		return

	var cur   = _active_label.visible_characters
	var total = _full_text.length()

	if cur >= total:
		_timer.stop()
		typing = false
		_active_label = null
		_stop_talking_anim()
		return

	_active_label.visible_characters += 1


# ======================================
# TALKING ANIMATION
func _get_base_scale(sprite: Node2D) -> Vector2:
	if sprite == king_sprite:
		return _king_base_scale
	elif sprite == keshar_sprite:
		return _keshar_base_scale
	elif sprite == visitor_sprite:
		return _visitor_base_scale
	return sprite.scale

func _tween_modulate(sprite: Node2D, color: Color, duration: float = 0.15) -> void:
	var old = _modulate_tweens.get(sprite)
	if old and old.is_valid():
		old.kill()
	var tw = sprite.create_tween()
	tw.tween_property(sprite, "modulate", color, duration)
	_modulate_tweens[sprite] = tw

func _start_talking_anim(sprite: Node2D) -> void:
	if sprite == null or not sprite.visible:
		return

	_stop_talking_anim()

	_active_sprite = sprite
	var base = _get_base_scale(sprite)
	_talk_tween = sprite.create_tween()
	_talk_tween.set_loops()
	_talk_tween.tween_property(sprite, "scale", base * 1.02, 0.22).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_talk_tween.tween_property(sprite, "scale", base, 0.22).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _stop_talking_anim() -> void:
	if _talk_tween and _talk_tween.is_valid():
		_talk_tween.kill()
		_talk_tween = null

	if _active_sprite and is_instance_valid(_active_sprite):
		var base = _get_base_scale(_active_sprite)
		var tw = _active_sprite.create_tween()
		tw.tween_property(_active_sprite, "scale", base, 0.1)

	_active_sprite = null

func _update_dim_by_bubble() -> void:
	# Cek siapa yang bubblenya visible
	var active_sprite: Node2D = null
	if king_label and king_label.get_parent().get_parent().visible:
		active_sprite = king_sprite
	elif keshar_label and keshar_label.get_parent().get_parent().visible:
		active_sprite = keshar_sprite
	elif visitor_label and visitor_label.get_parent().get_parent().visible:
		active_sprite = visitor_sprite

	for sp in [king_sprite, keshar_sprite, visitor_sprite]:
		if sp == null or not sp.visible:
			continue
		if active_sprite == null:
			# Tidak ada yang ngomong, semua bright
			_tween_modulate(sp, Color(1.0, 1.0, 1.0, 1.0))
		else:
			_tween_modulate(sp, Color(1.0, 1.0, 1.0, 1.0) if sp == active_sprite else Color(0.5, 0.5, 0.5, 1.0))


# ======================================
func _hide_bubble(label: RichTextLabel) -> void:
	label.text = ""
	label.visible_characters = 0
	var bubble = label.get_parent().get_parent()
	bubble.visible = false
	bubble.scale = Vector2(1.0, 1.0)
	bubble.modulate.a = 1.0

func _clear_labels() -> void:
	if king_label:    _hide_bubble(king_label)
	if keshar_label:  _hide_bubble(keshar_label)
	if visitor_label: _hide_bubble(visitor_label)
	_update_dim_by_bubble()

func force_stop():
	if _timer:
		_timer.stop()
	_stop_talking_anim()
	typing = false
	_active_label = null
	dialog_queue = []
	index = 0
	for lbl in [king_label, keshar_label, visitor_label]:
		if lbl:
			lbl.text = ""
			lbl.visible_characters = 0
			var bubble = lbl.get_parent().get_parent()
			bubble.visible = false
			bubble.scale = Vector2(1.0, 1.0)
			bubble.modulate.a = 1.0
	_update_dim_by_bubble()

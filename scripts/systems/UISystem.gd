extends Node

var day_label
var continue_btn

func setup(day_lbl,cont_btn):
	day_label = day_lbl
	continue_btn = cont_btn

func set_day(day,title):
	day_label.text = "Hari %d — %s" % [day,title]

func set_continue_text(text):
	continue_btn.text = text

func update_bar(bar: ProgressBar, label: Label, value: int):
	bar.value = value
	label.text = str(value)

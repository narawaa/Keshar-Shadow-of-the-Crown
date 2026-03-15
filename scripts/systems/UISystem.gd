extends Node

func update_bar(bar: ProgressBar, label: Label, value: int):
	bar.value = value
	label.text = str(value)

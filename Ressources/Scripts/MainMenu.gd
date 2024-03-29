extends CanvasLayer

@onready var main: Control = $Main
@onready var settings: Control = $Settings
@onready var credits: Control = $Credits
@onready var fullscreen = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$"Main/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Button-Start".grab_focus()
	$"../AudioStreamPlayer2D".play()



func _on_button_start_pressed():
	# get_tree().change_scene_to_file("res://Scenes/TestLevel.tscn")
	get_tree().change_scene_to_file("res://Scenes/forest_level.tscn")


func _on_button_options_pressed():
	main.visible = false
	settings.visible = true
	credits.visible = false
	$Settings/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/CheckButton.grab_focus()


func _on_button_credits_pressed():
	main.visible = false
	settings.visible = false
	credits.visible = true
	


func _on_button_quit_pressed():
	get_tree().quit()


func _on_button_back_pressed():
	main.visible = true
	settings.visible = false
	credits.visible = false
	$"Main/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Button-Start".grab_focus()


func _on_check_button_pressed():
	if fullscreen == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	fullscreen = !fullscreen

extends Control

@onready var resumeButton: Button = $"CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Button-Resume"
@onready var showPauseMenu: Control = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	$"CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Button-Resume".grab_focus()




func unpause():
	get_tree().paused = false
	showPauseMenu.visible = false
	
func pause():
	get_tree().paused = true
	showPauseMenu.visible = true


func _on_button_resume_pressed():
	unpause()


func _on_button_settings_pressed():
	pass # Replace with function body.


func _on_button_quit_menu_pressed():
	unpause()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_button_quit_game_pressed():
	get_tree().quit()

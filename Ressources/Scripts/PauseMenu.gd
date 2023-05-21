extends Control

@onready var Pause: Control = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	$"CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Button-Resume".grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_resume_pressed():
	Pause.visible = false


func _input(event):
	if event.is_action_pressed("pause_ui"):
		Pause.visible = !Pause.visible


func _on_button_settings_pressed():
	pass # Replace with function body.


func _on_button_quit_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_button_quit_game_pressed():
	get_tree().quit()

extends Camera2D


export(Color, RGB) var backgroundColor

func _ready():
	VisualServer.set_default_clear_color(backgroundColor)

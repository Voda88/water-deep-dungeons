extends Node2D

var game: Node = null

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if game == null or not is_instance_valid(game):
		return
	game.draw_projectiles_on_canvas(self)

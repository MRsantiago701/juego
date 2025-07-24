extends Node2D

func _on_area_2d_7_body_entered(_body: Node2D) -> void:
	get_tree().reload_current_scene()


func _on_area_2d_8_body_entered(body: Node2D) -> void:
	get_tree().change_scene_to_file("res://nivel2/nivel2d.tscn")

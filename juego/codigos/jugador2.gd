extends Node2D


func _on_area_2d_10_body_entered(body: Node2D) -> void:
	get_tree().reload_current_scene()


func _on_area_2d_17_body_entered(body: Node2D) -> void:
	get_tree().change_scene_to_file("res://nivel1/level1.tscn")

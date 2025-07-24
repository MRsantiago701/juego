extends Area2D

# Variable para el valor del puntaje que da esta moneda.
var valor_puntos : int = 1

func _ready():
	# Conectamos la señal de body_entered (cuando el jugador toca la moneda).
	body_entered.connect(_on_body_entered)
	add_to_group("monedas")  # Añade al grupo al cargar la escena

func _on_body_entered(body : Node):
	if body.is_in_group("jugador"):  # Asegurarse de que solo el jugador la recoja.
		body.sumar_puntos(valor_puntos)  # Llama a una función en el jugador.
		queue_free()  # Elimina la moneda de la escena.

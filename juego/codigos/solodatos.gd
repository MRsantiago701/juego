extends CharacterBody2D

# --- Variables del jugador ---
var vida : int = 100
var puntaje : int = 0
var velocidad : int = 300
var gravedad : int = 1000
var fuerza_salto : int = -400

@onready var label_puntaje : Label = $"../UI_Puntaje"

func _ready():
	actualizar_label()
	add_to_group("jugador")  # Añade al grupo al cargar la escena

func _physics_process(delta):
	# Movimiento y gravedad (como antes)
	if not is_on_floor():
		velocity.y += gravedad * delta
	
	var direccion = Input.get_axis("ui_left", "ui_right")
	velocity.x = direccion * velocidad
	
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = fuerza_salto
	
	move_and_slide()
	
	if Input.is_action_pressed("guardar"):
		guardar_datos()
	if Input.is_action_pressed("cargar"):
		cargar_datos()
	


# --- Sistema de puntos y Label ---
func sumar_puntos(cantidad : int):
	puntaje += cantidad
	actualizar_label()

func actualizar_label():
	label_puntaje.text = "Vida: %d\nPuntos: %d" % [vida, puntaje]
	


func guardar_datos():
	
	var datos = {
		"jugador": {
			"puntaje": puntaje,
			"vida": vida,
			"posicion": {
				"x": "%.8f" % global_position.x,
				"y": "%.8f" % global_position.y
			}			
		}
	}
	#Código para guardar JSON
	var json_texto = JSON.stringify(datos, "\t")
	var archivo = FileAccess.open("res://juego_guardado.json",FileAccess.WRITE)
	archivo.store_string(json_texto)
	archivo.close()
	print("Todo salió bien, archivo guardado")
	
	
func cargar_datos():
	
	if not FileAccess.file_exists("res://juego_guardado.json"):
		print("No hay archivo")
		return
		
	var archivo = FileAccess.open("res://juego_guardado.json",FileAccess.READ)
	var json_caracter = archivo.get_as_text()
	archivo.close()
	
	var json = JSON.new()
	var error = json.parse(json_caracter)
	if error != OK:
		print("No se parseó", json.get_error_message())
	
	var datos = json.get_data()
	
	global_position = Vector2(		
		float(datos["jugador"]["posicion"]["x"]),
		float(datos["jugador"]["posicion"]["y"])
	)
	
	vida = datos["jugador"]["vida"]
	puntaje = datos["jugador"]["puntaje"]
	actualizar_label()

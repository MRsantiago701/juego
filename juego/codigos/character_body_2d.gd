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
	
	# Guardar (G) / Cargar (L)
	if Input.is_action_just_pressed("guardar"):
		guardar_datos_json()
	if Input.is_action_just_pressed("cargar"):
		cargar_datos_json()

# --- Sistema de puntos y Label ---
func sumar_puntos(cantidad : int):
	puntaje += cantidad
	actualizar_label()

func actualizar_label():
	label_puntaje.text = "Vida: %d\nPuntos: %d" % [vida, puntaje]

# --- Guardado en JSON ---
func guardar_datos_json():
	var estado_objetos = []
	for moneda in get_tree().get_nodes_in_group("monedas"):
		estado_objetos.append({
			"nombre": moneda.name,
			"recolectada": not moneda.is_inside_tree(),
			"posicion": {
				"x": "%.8f" % moneda.global_position.x,  # 8 decimales de precisión
				"y": "%.8f" % moneda.global_position.y
			} if moneda.is_inside_tree() else {"x": "0.00000000", "y": "0.00000000"},
			"parent_path": str(moneda.get_parent().get_path()) if moneda.is_inside_tree() else ""

		})
	
	var datos = {
		"jugador": {
			"posicion": {"x": "%.8f" % global_position.x, "y": "%.8f" % global_position.y},
			"vida": vida,
			"puntaje": puntaje
		},
		"objetos": estado_objetos
	}
	
	var json_string = JSON.stringify(datos, "\t")
	var archivo = FileAccess.open("user://partida_guardada.json", FileAccess.WRITE)
	archivo.store_string(json_string)
	archivo.close()
	print("Datos guardados en JSON!")

func cargar_datos_json():
	if not FileAccess.file_exists("user://partida_guardada.json"):
		print("No hay archivo JSON guardado.")
		return
	
	var archivo = FileAccess.open("user://partida_guardada.json", FileAccess.READ)
	var json_string = archivo.get_as_text()
	archivo.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Error al parsear JSON: ", json.get_error_message())
		return
	
	var datos = json.get_data()
	
	# Limpiar objetos existentes
	for moneda in get_tree().get_nodes_in_group("monedas"):
		moneda.queue_free()
	
	# Cargar jugador con máxima precisión
	global_position = Vector2(
		float(datos["jugador"]["posicion"]["x"]),
		float(datos["jugador"]["posicion"]["y"])
	)
	vida = datos["jugador"]["vida"]
	puntaje = datos["jugador"]["puntaje"]
	actualizar_label()
	
	# Recrear objetos
	for objeto in datos["objetos"]:
		if !objeto["recolectada"]:
			var nueva_moneda = preload("res://escenas/object.tscn").instantiate()
			nueva_moneda.name = objeto["nombre"]
			
			# Asegurar que se añade al padre correcto
			var parent_node = get_node_or_null(objeto["parent_path"])
			if parent_node:
				parent_node.add_child(nueva_moneda)
				nueva_moneda.global_position = Vector2(
					float(objeto["posicion"]["x"]),
					float(objeto["posicion"]["y"])
				)
			else:
				printerr("No se encontró el nodo padre:", objeto["parent_path"])
	
	print("Datos cargados con precisión!")

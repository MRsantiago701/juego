# Nombre del juego : las runas
# Descripcion del juego 🕹️

Un juego 2D de plataformas donde controlas a un personaje que debe recoger monedas y evitar caer de las plataformas.
Si caes, mueres y debes reiniciar. El objetivo es recoger todas las monedas para avanzar al siguiente nivel. Además, puedes guardar
tu progreso en puntos específicos del juego, lo que te permite continuar desde donde te quedaste la próxima vez que juegues, sin perder tu avance.
# Caracteristicas del video juego 🕹️

•Cuenta con un sistema de conteo de monedas 

•Cuenta con monedas en cada nivel aumentando la dificultad del nivel 

•Sistema de guardado y carga el cuál guarda la ubicación y puntuación de dónde te ubicas 

•Plataforma fija y frágil
# Assets utilizados 🧩

fondos del nivel 1

"[mountains_b.zip](https://github.com/user-attachments/files/21554744/mountains_b.zip)"

"[lava.zip](https://github.com/user-attachments/files/21554766/lava.zip)"

fondo del nivel 2

"[water_a_8frames.zip](https://github.com/user-attachments/files/21554811/water_a_8frames.zip)"

"[desert_a.zip](https://github.com/user-attachments/files/21554817/desert_a.zip)"

Personaje

"[per.zip](https://github.com/user-attachments/files/21554861/per.zip)"

 Plataforma

 "[PS_Tileset_06.zip](https://github.com/user-attachments/files/21554918/PS_Tileset_06.zip)"

 Monedas 

 "[coin_silver.zip](https://github.com/user-attachments/files/21554962/coin_silver.zip)"

 Puerta

 "[Door.zip](https://github.com/user-attachments/files/21554975/Door.zip)"

 # Script 👩‍💻

  Perzonaje 

  ```gdscript

  extends CharacterBody2D

# --- Variables del jugador ---
var vida : int = 0
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
	label_puntaje.text = "Vida extras: %d\nmonedas: %d" % [vida, puntaje]

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


```
Puerta 

```gdscript

func _on_area_2d_8_body_entered(body: Node2D) -> void:
	get_tree().change_scene_to_file("res://nivel2/nivel2d.tscn")

```

Monedas 

```gdscript

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


```

Plataforma

```gdscript

extends Area2D

enum TipoPlataforma {FIJA, OSCILATORIA, FRAGIL, REBOTE}
@export var tipo: TipoPlataforma = TipoPlataforma.FIJA;
@export var fuerza_rebote := 2.0

func _ready():
	actualizar_plataforma()
	monitorable = true
	monitoring = true
	
func actualizar_plataforma():
	match tipo:
		TipoPlataforma.FIJA:
			$Sprite2D.modulate = Color.GREEN
		TipoPlataforma.OSCILATORIA:
			$Sprite2D.modulate = Color.BLUE
			oscilar()
		TipoPlataforma.FRAGIL:
			$Sprite2D.modulate = Color.RED
		TipoPlataforma.REBOTE:
			$Sprite2D.modulate = Color.YELLOW
		


	
func oscilar():
	var tween = create_tween()
	tween.tween_property(self,"position:x",position.x + 100,2)
	tween.tween_property(self,"position:x",position.x - 100,2)
	tween.set_loops()




func _on_body_entered(body: Node2D) -> void:

	if body.is_in_group("jugador"):
	
		match tipo:
			TipoPlataforma.FRAGIL:
				await get_tree().create_timer(0.5).timeout
				queue_free()
			TipoPlataforma.REBOTE:
				if body.has_method("puede_rebotar"):
					body.pauede_rebotar(fuerza_rebote)
				else:
					body.velocity.y = body.brinco * fuerza_rebote
	pass # Replace with function body.

```

zona de eliminacion

```gdscript
func _on_area_2d_7_body_entered(_body: Node2D) -> void:
	get_tree().reload_current_scene()

```

guardar y descargar 

```gdscript

{
	"jugador": {
		"posicion": {
			"x": "0",
			"y": "0"
		},
		"puntaje": 0,
		"vida": 100
	}
}

```
# videos 🎥


# Comentarios finales sobre la experiencia del desarrollo

Creo que la configuración de las cosas fueron un reto para poder
acomodar correctamente la estructura de los códigos y también las
confirmaciones de las plataformas fue una experiencia muy divertida

# juego final
"[juego_2025.1zip.zip](https://github.com/user-attachments/files/21555223/juego_2025.1zip.zip)"

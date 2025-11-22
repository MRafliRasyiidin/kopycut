extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var col: CollisionShape2D = $CollisionShape2D
@onready var target: Node2D = $target
@onready var marker: Marker2D = $target/Marker2D2
@onready var selector:Node2D = $"../selector"
@onready var tooltip: Node2D = $"../tooltip"
@onready var controls: Control = $"../../CanvasLayer/Control"
@onready var portal: TileMapLayer = $"../portal"




# Tilemap
@onready var map: TileMapLayer = $".."
@onready var layers:Dictionary = {}
#@onready var pickable := map.get_node("pickables")

@export var max_speed := 100.0
@export var acceleration := 500.0
@export var friction := 600.0



var last_direction := Vector2.DOWN  
var held_directions := []

var show_tooltip:bool = true

var radius_size := 3  # Either 3 or 5, default is 3x3
var disk_radius = null
var holding:bool = false
var object_held:Dictionary = {
	"source_id": -1,
	"atlas": [],
	"alt": 0,
	"radius_size": 3
}

var saved_disk:Array = []
var saved_layer:Dictionary = {
	"layer": "",
	"source_id": [],
	"atlas": [],
	"alt": [],
	"pos": []
}
var saved:bool = false

func _ready() -> void:
	
	print(selector)
	# Get tilemap layers
	for child in map.get_children():
		if child is TileMapLayer:
			if child.name == "portal": continue
			var layer:Dictionary = {child.name: child}
			layers.merge(layer)
			

func _physics_process(delta: float) -> void:
	var input_dir = get_input_direction()

	if input_dir != Vector2.ZERO:
		# Accelerate toward target direction
		velocity = velocity.move_toward(input_dir.normalized() * max_speed, acceleration * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	
	# Snap based on last_direction
	if held_directions.size() > 0:
		match held_directions[-1]:
			Vector2.UP:
			#target.rotation = -PI / 2
				target.rotation = PI
			Vector2.DOWN:
			#target.rotation = PI / 2
				target.rotation = 0.0
			Vector2.LEFT:
			#target.rotation = PI
				target.rotation = PI / 2
			Vector2.RIGHT:
				#target.rotation = 0.0
				target.rotation = -PI / 2


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	next_level()
	_tooltip()
	show_controls()
	var selector_on_map = map.local_to_map(marker.global_position)
	selector.global_position = map.map_to_local(selector_on_map)

func get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	return dir

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var dir := Vector2.ZERO

		match event.keycode:
			KEY_W: dir = Vector2.UP
			KEY_S: dir = Vector2.DOWN
			KEY_A: dir = Vector2.LEFT
			KEY_D: dir = Vector2.RIGHT

		if dir != Vector2.ZERO:
			if event.pressed:
				# Add to stack if not already held
				if dir not in held_directions:
					held_directions.append(dir)
			else:
				# Remove from stack on release
				held_directions.erase(dir)

	# Picking
	if event.is_action_pressed("pick"):
		pickup()
	if event.is_action_pressed("save_load"):
		saveload()
	if event.is_action_pressed("radius"):
		change_radius()

func get_surrounding_cells_with_diagonals(center: Vector2i) -> Array[Vector2i]:
	var surrounding: Array[Vector2i] = []

	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			if x_offset == 0 and y_offset == 0:
				continue
			var pos = center + Vector2i(x_offset, y_offset)
			surrounding.append(pos)

	return surrounding

func get_outer_ring_cells(center: Vector2i) -> Array[Vector2i]:
	var outer_ring: Array[Vector2i] = []

	for x_offset in range(-2, 3):
		for y_offset in range(-2, 3):
			# Skip the inner 3x3 area (range -1 to 1)
			if abs(x_offset) <= 1 and abs(y_offset) <= 1:
				continue
			var pos = center + Vector2i(x_offset, y_offset)
			outer_ring.append(pos)

	return outer_ring
		
func pickup():
	var pickables_layer = layers["pickables"] as TileMapLayer
	var coords := map.local_to_map(marker.global_position)
	
	match holding:
		true: # Player already holding
			if layers["objects"].get_cell_source_id(coords) != -1 or layers["collisions"].get_cell_source_id(coords) != -1:
				print("Can't place Quanta Disk here!")
				return
			pickables_layer.set_cell(coords, object_held["source_id"], object_held["atlas"])
			radius_size = object_held.get("radius_size", 3)
			update_disk_radius(coords)
			print("DROPPED")
			holding = false
		false: # Player empty handed
			if layers.has("pickables"):
				object_held["source_id"] = pickables_layer.get_cell_source_id(coords)
				object_held["atlas"] = pickables_layer.get_cell_atlas_coords(coords)
				object_held["alt"] = pickables_layer.get_cell_alternative_tile(coords)
				object_held["radius_size"] = radius_size
				if object_held["source_id"] != -1:
					print("PICKED: ", object_held)
					pickables_layer.set_cell(coords, -1)
					holding = true
				else:
					print("No tile found under player on 'pickables' layer.")
					holding = false
			else:
				print("No 'pickables' layer found in layers dictionary.")


				
func _tooltip():
	var coords: Vector2i = map.local_to_map(marker.global_position)
	var x = layers["pickables"].get_cell_source_id(coords)

	update_disk_radius(coords)

	if x != -1:
		if show_tooltip:
			show_tooltip = false
			for r in disk_radius:
				var expand = preload("res://misc/expand.tscn").instantiate()
				tooltip.add_child(expand)
				expand.global_position = map.map_to_local(r)
	else:
		clear_tooltip()


		
func clear_tooltip():
	if !show_tooltip:
		show_tooltip = true
		for child in tooltip.get_children():
				child.queue_free()

func saveload():
	var player_tile = map.local_to_map(global_position)
	var coords: Vector2i = map.local_to_map(marker.global_position)
	update_disk_radius(coords)

	if layers["pickables"].get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return

	if saved:  # Load
		for data: Dictionary in saved_disk:
			var layer: TileMapLayer = data["layer"]
			var source = data["source_id"]
			var atlas = data["atlas"]
			var alt = data["alt"]
			var pos = data["pos"]

			for i in pos.size():
				layer.set_cell(coords + pos[i], source[i], atlas[i], alt[i])

		saved = true
		saved_disk.clear()
		saved_layer = {
			"layer": "",
			"source_id": [],
			"atlas": [],
			"alt": [],
			"pos": []
		}
		print("Loaded surroundings")

		if not is_tile_free(player_tile):
			print("Player stuck! Searching for free tile...")
			var safe_tile = find_nearest_free_tile(player_tile)
			global_position = map.map_to_local(safe_tile)
			print("Moved player to: ", safe_tile)

	else:  # Save
		saved_disk.clear()
		for layer: TileMapLayer in layers.values():
			var data: Dictionary = {
				"layer": layer,
				"source_id": [],
				"atlas": [],
				"alt": [],
				"pos": []
			}
			for cell in disk_radius:
				data["source_id"].append(layer.get_cell_source_id(cell))
				data["atlas"].append(layer.get_cell_atlas_coords(cell))
				data["alt"].append(layer.get_cell_alternative_tile(cell))
				data["pos"].append(cell - coords)
			saved_disk.append(data)
		saved = true
		controls.label.text = "Load"
		print("Saved surroundings")
		


func change_radius():
	var coords := map.local_to_map(marker.global_position)
	
	if layers["pickables"].get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return
		
	if saved:
		print("Disk no longer functioning")
		return
	
	# Toggle radius size between 3 and 5
	radius_size = 5 if radius_size == 3 else 3
	print("Radius set to %dx%d" % [radius_size, radius_size])
	
	update_disk_radius(coords)
	clear_tooltip()


	
func update_disk_radius(coords: Vector2i) -> void:
	if radius_size == 3:
		disk_radius = get_surrounding_cells_with_diagonals(coords)
	elif radius_size == 5:
		disk_radius = get_outer_ring_cells(coords)

	
func is_tile_free(tile_pos: Vector2i) -> bool:
	if not layers.has("collisions") and not layers.has("objects"):
		return true
		
	var collision_layer: TileMapLayer = layers["collisions"]
	var objects_layer: TileMapLayer = layers["objects"]
	
	return collision_layer.get_cell_source_id(tile_pos) and objects_layer.get_cell_source_id(tile_pos) == -1

func find_nearest_free_tile(center: Vector2i) -> Vector2i:
	for radius in range(1, 4):
		for x_offset in range(-radius, radius + 1):
			for y_offset in range(-radius, radius + 1):
				var pos = center + Vector2i(x_offset, y_offset)
				if is_tile_free(pos):
					return pos
	return center

func show_controls():
	var coords = map.local_to_map(marker.global_position)
	if layers["pickables"].get_cell_source_id(coords) != -1:
		
		controls.visible = true
	else: controls.visible = false

func next_level():
	var coords = map.local_to_map(global_position)
	if portal.get_cell_source_id(coords) == -1:
		return

	var current_scene_path = get_tree().current_scene.scene_file_path  # e.g., "res://scenes/level_1.tscn"
	var scene_name = current_scene_path.get_file().get_basename()      # e.g., "level_1"

	# Use RegEx to extract level number
	var regex = RegEx.new()
	regex.compile("^level_(\\d+)$")
	var result = regex.search(scene_name)

	if result:
		var current_level = int(result.get_string(1))
		var next_level = current_level + 1
		var next_scene_path = "res://scenes/level_%d.tscn" % next_level

		if ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
		else:
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
			print("Next level not found:", next_scene_path)
	else:
		print("Scene name doesn't match level pattern:", scene_name)

extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var col: CollisionShape2D = $CollisionShape2D
@onready var target: Node2D = $target
@onready var marker: Marker2D = $target/Marker2D2
@onready var selector: Node2D = $"../selector"
@onready var tooltip: Node2D = $"../tooltip"
@onready var controls: Control = $"../../UI/Control"
@onready var portal: TileMapLayer = $"../portal"
@onready var anim: AnimationPlayer = $AnimationPlayer

var permanent_colliders_root: Node2D = null

# Tilemap
@onready var map: TileMapLayer = $".."
@onready var layers: Dictionary = {}
@onready var pickables: TileMapLayer = null  # Reference to pickables layer

@export var max_speed := 100.0
@export var acceleration := 500.0
@export var friction := 600.0

var last_direction := Vector2.DOWN  
var held_directions := []

var show_tooltip: bool = true

var radius_size := 3  # Either 3 or 5, default is 3
var disk_radius = null
var holding: bool = false
var object_held: Dictionary = {
	"source_id": -1,
	"atlas": [],
	"alt": 0,
	"radius_size": 3,
	"scene": null
}

func _ready() -> void:
	anim.play("idle")
	print(selector)
	
	# Get tilemap layers
	for child in map.get_children():
		if child is TileMapLayer:
			if child.name == "portal": continue
			var layer: Dictionary = {child.name: child}
			layers.merge(layer)
			
			# Store reference to pickables layer
			if child.name == "pickables":
				pickables = child
	
	_build_permanent_colliders()
	
	# Connect to pickables signals
	if pickables:
		pickables.copy_completed.connect(_on_copy_completed)
		pickables.cut_completed.connect(_on_cut_completed)
		pickables.paste_completed.connect(_on_paste_completed)

func _physics_process(delta: float) -> void:
	var input_dir = get_input_direction()

	if input_dir != Vector2.ZERO:
		if anim.current_animation != "walk":
			anim.play("walk")
		velocity = velocity.move_toward(input_dir.normalized() * max_speed, acceleration * delta)
		AudioController.play_walk()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		AudioController.stop_walk()
		if anim.current_animation != "idle":
			anim.play("idle")
	
	move_and_slide()
	
	# Snap based on last_direction
	if held_directions.size() > 0:
		match held_directions[-1]:
			Vector2.UP:
				target.rotation = PI
			Vector2.DOWN:
				target.rotation = 0.0
			Vector2.LEFT:
				target.rotation = PI / 2
				sprite.flip_h = true
			Vector2.RIGHT:
				target.rotation = -PI / 2
				sprite.flip_h = false

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
				if dir not in held_directions:
					held_directions.append(dir)
			else:
				held_directions.erase(dir)

	# Picking
	if event.is_action_pressed("pick"):
		pickup()
	if event.is_action_pressed("copy"):
		copy()
		AudioController.play_copy()
	if event.is_action_pressed("cut"):
		cut()
		AudioController.play_cut()
	if event.is_action_pressed("paste"):
		paste()
		AudioController.play_paste()
	if event.is_action_pressed("radius"):
		change_radius()
		AudioController.play_menu_click()

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
			if abs(x_offset) <= 1 and abs(y_offset) <= 1:
				continue
			var pos = center + Vector2i(x_offset, y_offset)
			outer_ring.append(pos)
	return outer_ring

func pickup():
	if not pickables:
		print("Pickables layer not found!")
		return
	
	var coords := map.local_to_map(marker.global_position)
	
	match holding:
		true: # Player already holding
			var blocked := false
			if layers.has("objects") and layers["objects"].get_cell_source_id(coords) != -1:
				blocked = true
			if layers.has("collisions") and layers["collisions"].get_cell_source_id(coords) != -1:
				blocked = true
			if layers.has("permanent") and layers["permanent"].get_cell_source_id(coords) != -1:
				blocked = true
			if layers.has("pickables") and layers["pickables"].get_cell_source_id(coords) != -1:
				blocked = true

			if blocked:
				print("Can't place Quanta Disk here!")
				return
				
			var tile_type = GlobalState.pickable_tile.get("hold")
			GlobalState.pickable_tile[coords] = tile_type
			GlobalState.pickable_tile.erase("hold")
			pickables.set_cell(coords, object_held["source_id"], object_held["atlas"], object_held["scene"])
			radius_size = object_held.get("radius_size", 3)
			update_disk_radius(coords)
			print("DROPPED")
			holding = false
			
		false: # Player empty handed
			object_held["source_id"] = pickables.get_cell_source_id(coords)
			object_held["atlas"] = pickables.get_cell_atlas_coords(coords)
			object_held["alt"] = pickables.get_cell_alternative_tile(coords)
			object_held["radius_size"] = radius_size
			object_held["scene"] = get_scene_from_tile(coords)
			
			if object_held["source_id"] != -1:
				print("PICKED: ", object_held)
				
				## Execute the cut removal when picking up after cut
				#if pickables.is_cut_pending(coords):  # CHANGED: pass coords
					#pickables.execute_cut_removal(coords)  # CHANGED: pass coords
				var preview_mode = GlobalState.pickable_tile.get(coords)
				GlobalState.pickable_tile["hold"] = preview_mode
				GlobalState.pickable_tile.erase(coords)
				pickables.set_cell(coords, -1)
				holding = true
			else:
				print("No tile found under player on 'pickables' layer.")
				holding = false


func get_scene_from_tile(coords: Vector2i) -> int:
	var source_id = pickables.get_cell_source_id(coords)
	var tile_source = pickables.tile_set.get_source(source_id)
	var scene_index = pickables.get_cell_alternative_tile(coords)
	#var packed_scene = tile_source.get_scene_tile_scene(scene_index)
	return scene_index

func _tooltip():
	print(GlobalState.pickable_tile)
	if not pickables:
		return
	
	var coords: Vector2i = map.local_to_map(marker.global_position)
	var player_tile: Vector2i = map.local_to_map(global_position)
	var x = pickables.get_cell_source_id(coords)

	update_disk_radius(coords)
	if x != -1:
		if show_tooltip:
			show_tooltip = false
			# Choose which tiles to preview based on mode
			var preview_tiles: Array[Vector2i]
			if pickables.get_preview_mode(coords) == "cut" or GlobalState.pickable_tile.get(coords) == "cut":  # CHANGED: pass coords
				preview_tiles = get_opposite_tiles(player_tile, coords)
			else:
				preview_tiles.assign(disk_radius)
				var blocked_cells := _collect_permanent_cells(disk_radius, coords)
				preview_tiles = preview_tiles.filter(func(tile): return not blocked_cells.has(tile))
			
			for r in preview_tiles:
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

func copy():
	if not pickables:
		return
	
	var coords: Vector2i = map.local_to_map(marker.global_position)
	update_disk_radius(coords)

	var blocked_cells := _collect_permanent_cells(disk_radius, coords)
	var type = pickables.get_cell_alternative_tile(coords)
	
	if type == 3:
		pickables.copy_disk(coords, disk_radius, blocked_cells)
		clear_tooltip()
		var atlas = pickables.get_cell_atlas_coords(coords)
		var source_id = pickables.get_cell_source_id(coords)
		pickables.set_cell(coords, source_id, atlas, 6)
		

func get_opposite_tiles(player_tile: Vector2i, disk_tile: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var diff = player_tile - disk_tile
	
	if diff.x < 0 and diff.y == 0:  # Player LEFT
		tiles.append(disk_tile + Vector2i(1, -1))
		tiles.append(disk_tile + Vector2i(1, 0))
		tiles.append(disk_tile + Vector2i(1, 1))
	elif diff.x > 0 and diff.y == 0:  # Player RIGHT
		tiles.append(disk_tile + Vector2i(-1, -1))
		tiles.append(disk_tile + Vector2i(-1, 0))
		tiles.append(disk_tile + Vector2i(-1, 1))
	elif diff.y < 0 and diff.x == 0:  # Player ABOVE
		tiles.append(disk_tile + Vector2i(-1, 1))
		tiles.append(disk_tile + Vector2i(0, 1))
		tiles.append(disk_tile + Vector2i(1, 1))
	elif diff.y > 0 and diff.x == 0:  # Player BELOW
		tiles.append(disk_tile + Vector2i(-1, -1))
		tiles.append(disk_tile + Vector2i(0, -1))
		tiles.append(disk_tile + Vector2i(1, -1))
	else:
		print("Player must be directly adjacent (not diagonal) to cut!")
	
	return tiles

func cut():
	if not pickables:
		return
	
	var player_tile: Vector2i = map.local_to_map(global_position)
	var coords: Vector2i = map.local_to_map(marker.global_position)
	update_disk_radius(coords)

	var cut_tiles_array = get_opposite_tiles(player_tile, coords)
	var type = pickables.get_cell_alternative_tile(coords)
	if type == 4:
		pickables.cut_disk(coords, cut_tiles_array)
		clear_tooltip()
		var atlas = pickables.get_cell_atlas_coords(coords)
		var source_id = pickables.get_cell_source_id(coords)
		pickables.set_cell(coords, source_id, atlas, 6)

func paste():
	if not pickables:
		return
	
	var player_tile = map.local_to_map(global_position)
	var coords: Vector2i = map.local_to_map(marker.global_position)
	update_disk_radius(coords)
	var paste_tiles = get_opposite_tiles(player_tile, coords)
	var is_cut_mode = pickables.get_paste_mode(coords) == "cut"  # CHANGED: pass coords
	
	if pickables.paste_disk(coords, paste_tiles, is_cut_mode):
		clear_tooltip()

		# Check if player is stuck after paste
		if not is_tile_free(player_tile):
			print("Player stuck! Searching for free tile...")
			var safe_tile = find_nearest_free_tile(player_tile)
			global_position = map.map_to_local(safe_tile)
			print("Moved player to: ", safe_tile)

func change_radius():
	if not pickables:
		return
	
	var coords := map.local_to_map(marker.global_position)
	
	if pickables.get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return
	
	if pickables.is_saved(coords):  # CHANGED: pass coords
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
	if not layers.has("collisions") and not layers.has("objects") and not layers.has("permanent"):
		return true
	
	var collision_blocked: bool = layers.has("collisions") and layers["collisions"].get_cell_source_id(tile_pos) != -1
	var permanent_blocked: bool = layers.has("permanent") and layers["permanent"].get_cell_source_id(tile_pos) != -1
	var objects_blocked: bool = layers.has("objects") and layers["objects"].get_cell_source_id(tile_pos) != -1

	return not (collision_blocked or permanent_blocked or objects_blocked)

func _build_permanent_colliders() -> void:
	if permanent_colliders_root and permanent_colliders_root.is_inside_tree():
		permanent_colliders_root.queue_free()
		permanent_colliders_root = null

	if not layers.has("permanent"):
		return

	var perm := layers["permanent"] as TileMapLayer
	permanent_colliders_root = Node2D.new()
	permanent_colliders_root.name = "PermanentColliders"
	permanent_colliders_root.visible = false
	perm.add_child(permanent_colliders_root)

	var tile_size := perm.tile_set.tile_size
	for cell in perm.get_used_cells():
		if perm.get_cell_source_id(cell) == -1:
			continue

		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 1
		body.position = perm.map_to_local(cell)

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(tile_size.x, tile_size.y)
		shape.shape = rect
		body.add_child(shape)
		permanent_colliders_root.add_child(body)

func find_nearest_free_tile(center: Vector2i) -> Vector2i:
	for radius in range(1, 4):
		for x_offset in range(-radius, radius + 1):
			for y_offset in range(-radius, radius + 1):
				var pos = center + Vector2i(x_offset, y_offset)
				if is_tile_free(pos):
					return pos
	return center

func _collect_permanent_cells(cells: Array[Vector2i], center: Vector2i) -> Dictionary:
	var blocked := {}
	var blocked_layers := ["permanent"]  # Add any layers you want to block
	for layer_name in blocked_layers:
		if not layers.has(layer_name):
			continue
		var layer: TileMapLayer = layers[layer_name]
		if layer.get_cell_source_id(center) != -1:
			blocked[center] = true
		for cell in cells:
			if layer.get_cell_source_id(cell) != -1:
				blocked[cell] = true
	return blocked

func show_controls():
	if not pickables:
		return
	
	var coords = map.local_to_map(marker.global_position)
	#if pickables.get_cell_source_id(coords) != -1:
		#controls.visible = true
	#else:
		#controls.visible = false

func next_level():
	var coords = portal.local_to_map(global_position)
	if portal.get_cell_source_id(coords) == -1:
		return

	var current_scene_path = get_tree().current_scene.scene_file_path
	var scene_name = current_scene_path.get_file().get_basename()

	var regex = RegEx.new()
	regex.compile("^level_(\\d+)$")
	var result = regex.search(scene_name)

	if result:
		var current_level = int(result.get_string(1))
		var next_level = current_level + 1
		var next_scene_path = "res://scenes/level_%d.tscn" % next_level

		if ResourceLoader.exists(next_scene_path):
			GlobalState.level += 1
			get_tree().change_scene_to_file(next_scene_path)
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			print("Next level not found:", next_scene_path)
	else:
		print("Scene name doesn't match level pattern:", scene_name)

# Signal handlers
func _on_copy_completed():
	controls.label.text = "Paste"

func _on_cut_completed():
	controls.label.text = "Paste"

func _on_paste_completed():
	controls.label.text = "Copy"

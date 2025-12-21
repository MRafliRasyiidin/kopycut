extends TileMapLayer

@onready var map: TileMapLayer = get_parent()
var layers: Dictionary = {}
const NON_COPYABLE_LAYERS := ["permanent", "Turret", "pickables"]
var disk_memories: Dictionary = {}

signal copy_completed
signal cut_completed
signal paste_completed

func _ready() -> void:
	# Get all tilemap layers from parent
	for child in map.get_children():
		if child is TileMapLayer:
			if child.name == "portal": continue
			var layer: Dictionary = {child.name: child}
			layers.merge(layer)

func get_disk_id(coords: Vector2i) -> String:
	var source = get_cell_source_id(coords)
	var atlas = get_cell_atlas_coords(coords)
	#var alt = get_cell_alternative_tile(coords)
	return "%d_%s" % [source, atlas]
	
func copy_disk(coords: Vector2i, disk_radius: Array[Vector2i], blocked_cells: Dictionary) -> void:
	if get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return
	
	var disk_id = get_disk_id(coords)
	# Initialize or reset this disk's memory
	GlobalState.pickable_tile[coords].merge({
		"saved_disk": [],
		"saved": false,
		"cut_pending": false,
		"cut_tiles": [],
		"preview_mode": "copy",
		"paste_mode": "copy"
	}, true)
	var memory = GlobalState.pickable_tile[coords]
	memory["preview_mode"] = "copy"
	memory["paste_mode"] = "copy"
	memory["cut_pending"] = false
	memory["cut_tiles"] = []
	memory["saved_disk"] = []
	
	for layer: TileMapLayer in layers.values():
		if layer.name in NON_COPYABLE_LAYERS:
			continue
		var data: Dictionary = {
			"layer": layer,
			"source_id": [],
			"atlas": [],
			"alt": [],
			"pos": []
		}
		for cell in disk_radius:
			if blocked_cells.has(cell):
				continue
			data["source_id"].append(layer.get_cell_source_id(cell))
			data["atlas"].append(layer.get_cell_atlas_coords(cell))
			data["alt"].append(layer.get_cell_alternative_tile(cell))
			data["pos"].append(cell - coords)
		memory["saved_disk"].append(data)
	
	memory["saved"] = true
	copy_completed.emit()
	print("Copied to disk: ", disk_id)

func cut_disk(coords: Vector2i, cut_tiles_to_save: Array[Vector2i]) -> void:
	if get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return
	if cut_tiles_to_save.is_empty():
		return
	
	var disk_id = get_disk_id(coords)
	
	# Initialize this disk's memory if it doesn't exist
	var memory = GlobalState.pickable_tile[coords]
	memory["cut_tiles"] = cut_tiles_to_save.duplicate()
	memory["saved_disk"] = []
	# Save only the cut tiles
	for layer: TileMapLayer in layers.values():
		var data: Dictionary = {
			"layer": layer,
			"source_id": [],
			"atlas": [],
			"alt": [],
			"pos": []
		}
		for cell in memory["cut_tiles"]:
			data["source_id"].append(layer.get_cell_source_id(cell))
			data["atlas"].append(layer.get_cell_atlas_coords(cell))
			data["alt"].append(layer.get_cell_alternative_tile(cell))
			data["pos"].append(cell - coords)
		memory["saved_disk"].append(data)
	memory["saved"] = true
	memory["cut_pending"] = true
	memory["preview_mode"] = "cut"
	memory["paste_mode"] = "cut"
	cut_completed.emit()
	print("Cut prepared on disk: ", disk_id)

func execute_cut_removal(coords: Vector2i) -> void:
	"""Execute the actual removal of cut tiles when disk is picked up"""
	var disk_id = get_disk_id(coords)
	if not GlobalState.pickable_tile.has(coords):
		return
	var memory = GlobalState.pickable_tile[coords]
	if not memory["cut_pending"]:
		return
	for layer: TileMapLayer in layers.values():
		if layer.name == "pickables":
			continue
		for cell in memory["cut_tiles"]:
			layer.set_cell(cell, -1)
	
	memory["cut_pending"] = false
	memory["cut_tiles"] = []
	print("Cut tiles removed for disk: ", disk_id)

func paste_disk(coords: Vector2i, paste_tiles: Array[Vector2i], is_cut_mode: bool) -> bool:
	if get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return false
	
	var disk_id = get_disk_id(coords)
	if not GlobalState.pickable_tile.has(coords):
		print("No data saved on this disk!")
		return false
	
	var memory = GlobalState.pickable_tile[coords]
	if not memory.get("saved"):
		print("No data to paste on this disk!")
		return false
	
	print("Pasting with mode: ", memory["paste_mode"])
	
	if memory["paste_mode"] == "cut" and memory["cut_pending"]:
		for layer: TileMapLayer in layers.values():
			if layer.name == "pickables" or layer.name == "collisions":
				continue
			for cell in memory["cut_tiles"]:
				layer.set_cell(cell, -1)
		print("Cut tiles removed during paste")
	
	if memory["paste_mode"] == "cut":
		# Cut-paste: place tiles on opposite side
		if paste_tiles.is_empty():
			return false
		
		for data: Dictionary in memory["saved_disk"]:
			var layer: TileMapLayer = data["layer"]
			if layer.name in NON_COPYABLE_LAYERS:
				continue
			var source = data["source_id"]
			var atlas = data["atlas"]
			var alt = data["alt"]
			
			for i in min(paste_tiles.size(), source.size()):
				var dest: Vector2i = paste_tiles[i]
				if _is_permanent_at(dest):
					continue
				layer.set_cell(dest, source[i], atlas[i], alt[i])
		
		print("Pasted to opposite side (cut mode)")
	else:
		# Copy-paste: use original relative positions
		for data: Dictionary in memory["saved_disk"]:
			var layer: TileMapLayer = data["layer"]
			if layer.name in NON_COPYABLE_LAYERS:
				continue
			var source = data["source_id"]
			var atlas = data["atlas"]
			var alt = data["alt"]
			var pos = data["pos"]
			
			for i in pos.size():
				var dest: Vector2i = coords + pos[i]
				if _is_permanent_at(dest):
					continue
				layer.set_cell(dest, source[i], atlas[i], alt[i])
		
		print("Pasted with relative positions (copy mode)")
	
	# Clear this disk's state after paste
	memory["saved"] = false
	memory["saved_disk"] = []
	memory["paste_mode"] = "copy"
	memory["preview_mode"] = "copy"
	memory["cut_pending"] = false
	memory["cut_tiles"] = []
	set_cell(coords, -1)  # Remove the disk
	
	paste_completed.emit()
	return true

func get_preview_mode(coords: Vector2i) -> String:
	#var disk_id = get_disk_id(coords)
	#if disk_memories.has(disk_id):
		#return disk_memories[disk_id]["preview_mode"]
	var type = get_cell_alternative_tile(coords)
	if type == 4:
		return "cut"
	elif type == 3:
		return "copy"
	else:
		return "default"

func get_paste_mode(coords: Vector2i) -> String:
	var disk_id = get_disk_id(coords)
	if disk_memories.has(disk_id):
		return disk_memories[disk_id]["paste_mode"]
	return "copy"

func is_saved(coords: Vector2i) -> bool:
	var disk_id = get_disk_id(coords)
	if disk_memories.has(disk_id):
		return disk_memories[disk_id]["saved"]
	return false

func is_cut_pending(coords: Vector2i) -> bool:
	var disk_id = get_disk_id(coords)
	if disk_memories.has(disk_id):
		return disk_memories[disk_id]["cut_pending"]
	return false

func _is_permanent_at(tile_pos: Vector2i) -> bool:
	return layers.has("permanent") and layers["permanent"].get_cell_source_id(tile_pos) != -1

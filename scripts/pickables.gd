extends TileMapLayer

@onready var map: TileMapLayer = get_parent()
var layers: Dictionary = {}

const NON_COPYABLE_LAYERS := ["permanent", "objects", "Turret"]

# Cut/Copy/Paste state
var saved_disk: Array = []
var saved: bool = false
var cut_pending: bool = false
var cut_tiles: Array[Vector2i] = []
var preview_mode: String = "copy"
var paste_mode: String = "copy"

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

func copy_disk(coords: Vector2i, disk_radius: Array[Vector2i], blocked_cells: Dictionary) -> void:
	if get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return
	
	# Reset cut state if switching to copy
	cut_pending = false
	cut_tiles.clear()
	preview_mode = "copy"
	paste_mode = "copy"
	
	saved_disk.clear()
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
		saved_disk.append(data)
	
	saved = true
	copy_completed.emit()
	print("Copy mode - paste_mode set to: ", paste_mode)

func cut_disk(coords: Vector2i, cut_tiles_to_save: Array[Vector2i]) -> void:
	if get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return
	
	if cut_tiles_to_save.is_empty():
		return
	
	cut_tiles = cut_tiles_to_save.duplicate()
	
	# Save only the cut tiles
	saved_disk.clear()
	for layer: TileMapLayer in layers.values():
		var data: Dictionary = {
			"layer": layer,
			"source_id": [],
			"atlas": [],
			"alt": [],
			"pos": []
		}
		for cell in cut_tiles:
			data["source_id"].append(layer.get_cell_source_id(cell))
			data["atlas"].append(layer.get_cell_atlas_coords(cell))
			data["alt"].append(layer.get_cell_alternative_tile(cell))
			data["pos"].append(cell - coords)
		saved_disk.append(data)
	
	saved = true
	cut_pending = true
	preview_mode = "cut"
	paste_mode = "cut"
	cut_completed.emit()
	print("Cut prepared - pick up disk to remove tiles: ", cut_tiles)

func execute_cut_removal() -> void:
	"""Execute the actual removal of cut tiles when disk is picked up"""
	if not cut_pending:
		return
	
	for layer: TileMapLayer in layers.values():
		if layer.name == "pickables":
			continue
		for cell in cut_tiles:
			layer.set_cell(cell, -1)
	
	cut_pending = false
	cut_tiles.clear()
	print("Cut tiles removed")

func paste_disk(coords: Vector2i, paste_tiles: Array[Vector2i], is_cut_mode: bool) -> bool:
	if get_cell_source_id(coords) == -1:
		print("No Quanta Disk found!")
		return false
	
	if not saved:
		print("No data to paste!")
		return false
	
	print("Pasting with paste_mode: ", paste_mode)
	
	if is_cut_mode:
		# Cut-paste: place tiles on opposite side
		if paste_tiles.is_empty():
			return false
		
		for data: Dictionary in saved_disk:
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
		for data: Dictionary in saved_disk:
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
	
	# Clear state after paste
	saved = false
	saved_disk.clear()
	paste_mode = "copy"
	preview_mode = "copy"
	cut_pending = false
	cut_tiles.clear()
	set_cell(coords, -1)  # Remove the disk
	
	paste_completed.emit()
	return true

func get_preview_mode() -> String:
	return preview_mode

func get_paste_mode() -> String:
	return paste_mode

func is_saved() -> bool:
	return saved

func is_cut_pending() -> bool:
	return cut_pending

func reset_state() -> void:
	saved = false
	saved_disk.clear()
	paste_mode = "copy"
	preview_mode = "copy"
	cut_pending = false
	cut_tiles.clear()

func _is_permanent_at(tile_pos: Vector2i) -> bool:
	return layers.has("permanent") and layers["permanent"].get_cell_source_id(tile_pos) != -1

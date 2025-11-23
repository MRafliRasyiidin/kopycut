extends TileMapLayer

@onready var portal: TileMapLayer = $"."

func _ready() -> void:
	var tiles = portal.get_used_cells()
	var portal_tile_coord = tiles[0]
	var portal_cell = portal.get_scene_instance_load_placeholder()
	print(portal_cell)
	
	
	

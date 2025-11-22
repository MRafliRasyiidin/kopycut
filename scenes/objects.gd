extends TileMapLayer

var object: Array

func _ready() -> void:
	object = self.get_used_cells()
	

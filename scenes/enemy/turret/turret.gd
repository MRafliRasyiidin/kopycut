extends TileMapLayer

@onready var timer: Timer = $Timer
@export var ammo: PackedScene
@onready var turret_tile = $"."
var turrets: Array

func _ready() -> void:
	timer.start()
	turrets = turret_tile.get_used_cells()

func _process(delta: float) -> void:
	var temp_turrets = turret_tile.get_used_cells()
	if temp_turrets == turrets:
		return
	else:
		turrets = temp_turrets

func _on_timer_timeout():
	_shoot()

func _shoot():
	
	print("SHOT")
	for pos in turrets:
		var tile_pos = pos
		var world_pos = turret_tile.map_to_local(tile_pos)
		var bullet = ammo.instantiate()
		bullet.position = world_pos + Vector2(50, -20)
		get_tree().current_scene.add_child(bullet)
		AudioController.play_turret_shoot()

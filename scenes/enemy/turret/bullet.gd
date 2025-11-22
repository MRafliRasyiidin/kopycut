extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
#	TODO Add game over
	print("Node berasal dari scene:", body.get_path()) 
	print(body.is_in_group("Obstacle"))
	if body.is_in_group("Player") or body.is_in_group("Obstacle"):
		queue_free()
		
func set_direction(direction: Vector2):
	self.direction = direction
	
func set_speed(speed: float):
	self.speed = speed

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Obstacle"):
		queue_free()

shader_type canvas_item;

uniform float speed = 0.5;

void vertex() {
	UV.x += speed * TIME;
	UV.y += speed * TIME;
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

shader_type canvas_item;

void fragment() {
	float line = mod(FRAGCOORD.y, 4.0);
	if (line < 2.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.08);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}

shader_type canvas_item;

uniform float scroll_speed : hint_range(0.0, 5.0) = 0.5;
uniform vec4  line_color   : source_color = vec4(0.0, 0.831, 1.0, 0.35);
uniform float grid_size    : hint_range(10.0, 200.0) = 80.0;

void fragment() {
	vec2 uv = UV;

	// Perspective warp: lines converge toward the horizon (top of rect)
	float perspective = mix(0.1, 1.0, uv.y);
	vec2 grid_uv = vec2(
		(uv.x - 0.5) / perspective + 0.5,
		1.0 / (1.0 - uv.y + 0.01)
	);
	grid_uv.y += TIME * scroll_speed;

	// Grid line mask
	vec2  grid = abs(fract(grid_uv * grid_size) - 0.5);
	float line = min(grid.x, grid.y);
	float mask = 1.0 - smoothstep(0.0, 0.02, line);

	// Fade lines near the horizon (top of rect)
	float fade = smoothstep(0.0, 0.6, uv.y);

	COLOR = line_color * mask * fade;
}

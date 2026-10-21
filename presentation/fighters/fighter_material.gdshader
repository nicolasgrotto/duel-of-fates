shader_type canvas_item;

uniform vec4 palette[8];
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color = vec4(1.0);

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 data = texture(TEXTURE, UV);
	int slot = clamp(int(round(data.g * 7.0)), 0, 7);
	vec3 base = palette[slot].rgb;
	vec3 color = base * data.r * 2.0 + palette[7].rgb * data.b;
	color = mix(color, flash_color.rgb, flash);
	COLOR = vec4(color, data.a) * modulate;
}

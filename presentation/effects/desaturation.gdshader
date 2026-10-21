shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float darken : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(color, vec3(gray) * (1.0 - darken), amount), 1.0);
}

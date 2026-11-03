shader_type canvas_item;

uniform vec4 palette[8];
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color = vec4(1.0);
uniform bool clip_enabled = false;
uniform vec2 clip_point = vec2(0.0);
uniform vec2 clip_normal = vec2(0.0, 1.0);
uniform bool clip2_enabled = false;
uniform vec2 clip2_point = vec2(0.0);
uniform vec2 clip2_normal = vec2(0.0, 1.0);
uniform float charred : hint_range(0.0, 1.0) = 0.0;
uniform vec4 charred_color = vec4(0.16, 0.11, 0.09, 1.0);
uniform float xray : hint_range(0.0, 1.0) = 0.0;
uniform vec4 xray_color = vec4(0.07, 0.08, 0.12, 1.0);
uniform bool prosthetic = false;
uniform vec4 prosthetic_color = vec4(0.55, 0.58, 0.62, 1.0);

varying vec4 modulate;
varying vec2 world_position;

void vertex() {
	modulate = COLOR;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (clip_enabled && dot(world_position - clip_point, clip_normal) < 0.0) {
		discard;
	}
	if (clip2_enabled && dot(world_position - clip2_point, clip2_normal) < 0.0) {
		discard;
	}
	vec4 data = texture(TEXTURE, UV);
	int slot = clamp(int(round(data.g * 7.0)), 0, 7);
	vec3 base = prosthetic && slot != 7 ? prosthetic_color.rgb : palette[slot].rgb;
	vec3 color = base * data.r * 2.0 + palette[7].rgb * data.b;
	color = mix(color, charred_color.rgb * (0.6 + data.r * 0.8), charred);
	color = mix(color, xray_color.rgb, xray);
	color = mix(color, flash_color.rgb, flash);
	COLOR = vec4(color, data.a) * modulate;
}

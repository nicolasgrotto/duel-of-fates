shader_type canvas_item;
render_mode blend_add;

uniform vec4 tint = vec4(1.0);

void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a * COLOR.a);
}

shader_type canvas_item;

void fragment() {
	vec2 texel = UV / TEXTURE_PIXEL_SIZE;
	vec2 screen_per_texel = 1.0 / max(fwidth(texel), vec2(1e-4));
	vec2 edge = round(texel);
	vec2 offset = clamp((texel - edge) * screen_per_texel, -0.5, 0.5);
	COLOR = texture(TEXTURE, (edge + offset) * TEXTURE_PIXEL_SIZE);
}

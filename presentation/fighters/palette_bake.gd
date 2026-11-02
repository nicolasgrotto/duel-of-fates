class_name PaletteBake
extends RefCounted

const LIGHT_SCALE: float = 2.0
const SLOT_SCALE: float = 7.0


static func texture(source: Texture2D, colors: PackedColorArray) -> ImageTexture:
	var image: Image = source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var encoded: Color = image.get_pixel(x, y)
			if encoded.a <= 0.0:
				continue
			var slot: int = clampi(roundi(encoded.g * SLOT_SCALE), 0, colors.size() - 1)
			var color: Color = colors[slot] * encoded.r * LIGHT_SCALE + colors[CostumeData.Slot.EYES] * encoded.b
			image.set_pixel(x, y, Color(color.r, color.g, color.b, encoded.a))
	return ImageTexture.create_from_image(image)

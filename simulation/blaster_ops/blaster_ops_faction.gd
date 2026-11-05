class_name BlasterOpsFaction
extends RefCounted

enum Side { ALLIED, HOSTILE }


static func of_bolt(bolt: InfiltrationBolt) -> BlasterOpsFaction.Side:
	return BlasterOpsFaction.Side.ALLIED if bolt.owner == 0 else BlasterOpsFaction.Side.HOSTILE

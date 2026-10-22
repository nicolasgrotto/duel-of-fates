class_name InteractionTable
extends Resource

@export var bands: Array[InteractionBand] = []


func band_for(difference: int) -> InteractionBand:
	for band in bands:
		if difference >= band.min_difference:
			return band
	return bands[bands.size() - 1]

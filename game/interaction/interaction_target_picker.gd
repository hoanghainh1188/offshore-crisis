class_name InteractionTargetPicker
extends RefCounted
## Chooses which in-range target receives the interaction.


## Returns the candidate nearest to origin, or null when there is none.
## Candidates must be in entry order: on an exact tie the earlier one wins,
## which is why the comparison below is strict.
static func pick_nearest(origin: Vector2, candidates: Array[Interactable]) -> Interactable:
	var best: Interactable = null
	var best_distance: float = INF
	for candidate: Interactable in candidates:
		var distance: float = origin.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best

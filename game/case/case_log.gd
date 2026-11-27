class_name CaseLog
extends RefCounted
## Log line for a new case (specs/run-flow). Only the seed: logging the root cause would
## give the answer away in the browser console.


static func format(seed_value: int) -> String:
	return "[case] seed %d" % seed_value

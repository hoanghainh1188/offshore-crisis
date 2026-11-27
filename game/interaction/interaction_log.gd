class_name InteractionLog
extends RefCounted
## Builds the console line for an interaction (format fixed by specs/world-interaction).


static func format(kind_name: String, id: StringName, display_name: String) -> String:
	return '[interact] %s:%s "%s"' % [kind_name, id, display_name]

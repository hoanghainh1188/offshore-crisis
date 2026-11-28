class_name DialogueAnswer
extends RefCounted
## What an NPC says to one question, and which fact (if any) that answer reveals.

var text: String = ""
## The fact this answer reveals, or &"" for a non-answer.
var reveals: StringName = &""

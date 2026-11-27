class_name BriefingEmail
extends Resource
## The client's escalation email shown on the briefing screen. Text is data, not code;
## all names and companies are fictional.

@export var sender: String = ""
@export var subject: String = ""
@export_multiline var body: String = ""

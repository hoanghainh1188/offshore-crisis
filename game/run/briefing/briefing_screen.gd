class_name BriefingScreen
extends Control
## Shows the client's escalation email before the run starts (specs/run-flow).
## The clock is not running here; Start hands control to the Run scene.

## Emitted once, when the player presses Start.
signal start_pressed

@export var email: BriefingEmail = preload("res://run/briefing/wrong_delivery_email.tres")

var _started: bool = false

@onready var _sender_label: Label = %SenderLabel
@onready var _subject_label: Label = %SubjectLabel
@onready var _body_label: Label = %BodyLabel
@onready var _time_label: Label = %TimeLabel
@onready var _start_button: Button = %StartButton


func _ready() -> void:
	_sender_label.text = "From: %s" % email.sender
	_subject_label.text = "Subject: %s" % email.subject
	_body_label.text = email.body
	_time_label.text = RunClock.format_office_time(RunClock.START_MINUTES)
	_start_button.pressed.connect(_on_start_button_pressed)
	# Focus first so Enter / Space (ui_accept) start the run without the mouse.
	_start_button.grab_focus()


func _on_start_button_pressed() -> void:
	if _started:
		return
	_started = true
	_start_button.disabled = true
	start_pressed.emit()

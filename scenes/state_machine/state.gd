class_name GolState
extends Node

enum State { DRAW, SELECT, RUN, UI }

@warning_ignore("UNUSED_SIGNAL")
signal transition_requested(from: GolState, to: State)

@export var state: State

var gol: GameOfLife


func enter() -> void:
    gol.update_model_label(State.keys()[state].capitalize())


func exit() -> void:
    pass


func on_process(_delta: float) -> void:
    pass


func on_input(_event: InputEvent):
    pass


func on_gui_input(_event: InputEvent):
    pass


func on_unhandled_input(_event: InputEvent):
    pass
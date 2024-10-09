class_name GolStateMachine
extends Node

@export var initial_state: GolState

var current_state = null
var states := {}


func init(gol: GameOfLife) -> void:
    for child: GolState in get_children():
        states[child.state] = child
        child.gol = gol
        child.transition_requested.connect(on_transition_requested)

    if initial_state:
        current_state = initial_state
        current_state.enter()


func on_process(delta: float):
    if current_state:
        current_state.on_process(delta)


func on_input(event: InputEvent):
    if current_state:
        current_state.on_input(event)


func on_gui_input(event: InputEvent):
    if current_state:
        current_state.on_gui_input(event)


func on_unhandled_input(event: InputEvent):
    if current_state:
        current_state.on_unhandled_input(event)


func on_transition_requested(from: GolState, to: GolState.State):
    if from != current_state:
        return

    var next_state: GolState = states[to]
    if not next_state:
        return

    if current_state:
        current_state.exit()
    current_state = next_state
    current_state.enter()

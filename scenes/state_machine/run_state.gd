class_name RunState
extends GolState


func enter() -> void:
    super.enter()
    gol.stopped = false


func on_unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("play_or_pause"):
        transition_requested.emit(self, State.DRAW)
    
    gol.handle_update_interval_event(event)
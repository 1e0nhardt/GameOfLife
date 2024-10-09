class_name DrawState
extends GolState


func enter() -> void:
    super.enter()
    gol.stopped = true


func on_process(_delta: float) -> void:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        gol.draw_point_at_mouse_on_renderer(true)
        
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        gol.draw_point_at_mouse_on_renderer(false)


func on_unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("change_rule"):
        gol.rule_edit.show()
        gol.rule_edit.grab_focus()
        
    if event.is_action_pressed("play_or_pause"):
        transition_requested.emit(self, State.RUN)
    
    if event.is_action_pressed("change_mode"):
        transition_requested.emit(self, State.SELECT)
    
    gol.handle_update_interval_event(event)

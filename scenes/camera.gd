class_name GameOfLifeCamera
extends Camera2D

@export var max_zoom_level: float = 256.0
@export var zoom_decay: float = 20.0
@export var move_speed: float = 800.0

var _input_direction: Vector2
var _current_zoom_level := 1.0
var _pan_active := false


func _process(delta: float) -> void:
    offset += _input_direction * delta * move_speed * (1.0 + 2.0 * float(Input.is_key_pressed(KEY_SHIFT))) / _current_zoom_level
    
    offset = offset.clamp(
        Vector2(0, -420),
        Vector2(1920 * (1.0 - 1.0 / _current_zoom_level), 420 + 1080 * (1.0 - 1.0 / _current_zoom_level))
    )


func _unhandled_input(event: InputEvent) -> void:
    _input_direction = Input.get_vector(
        "camera_move_left", "camera_move_right",
        "camera_move_up", "camera_move_down"
    )

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_MIDDLE:
            _pan_active = event.is_pressed()
        
        if not event.ctrl_pressed:
            if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                _zoom_canvas(_current_zoom_level * 1.2, get_local_mouse_position())
            elif event.button_index ==  MOUSE_BUTTON_WHEEL_DOWN:
                _zoom_canvas(_current_zoom_level / 1.2, get_local_mouse_position())
    
    if event is InputEventMouseMotion:
        if _pan_active:
            _do_pan(event.relative)


func _do_pan(pan: Vector2) -> void:
    offset -= pan * (1.0 / _current_zoom_level)


func _zoom_canvas(target_zoom: float, anchor: Vector2) -> void:
    target_zoom = clamp(target_zoom, 1, max_zoom_level)

    if target_zoom == _current_zoom_level:
        return

    # Pan canvas to keep content fixed under the cursor
    var zoom_center = anchor - offset
    var ratio = _current_zoom_level / target_zoom - 1.0
    offset -= zoom_center * ratio

    _current_zoom_level = target_zoom
    zoom = Vector2.ONE * _current_zoom_level
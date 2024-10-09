class_name ItemLabel
extends PanelContainer

const SELECTED_STYLE = preload("res://scenes/item_label_selected.tres")
var hovering_style: StyleBox

@onready var label: Label = %Label

var _panel_color := Color("a2c28f00")

var text := "":
    get(): return label.text
    set(value):
        label.text = value

var selected := false:
    set(value):
        selected = value
        if not selected:
            hovering = false
        queue_redraw()

var hovering := false:
    set(value):
        hovering = value
        if not selected:
            _panel_color.a = float(value)
            queue_redraw()


func _ready():
    label.mouse_entered.connect(func(): hovering = true)
    label.mouse_exited.connect(func(): hovering = false)


func _draw() -> void:
    if selected:
        draw_style_box(SELECTED_STYLE, Rect2(Vector2.ZERO, get_size()))
    else:
        draw_rect(Rect2(Vector2.ZERO, get_size()), _panel_color)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            EventBus.item_clicked.emit(self)

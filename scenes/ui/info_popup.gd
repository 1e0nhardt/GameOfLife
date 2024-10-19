@tool
class_name InfoPopup
extends PopupManager.PopupControl

var title: String = "Information":
    set = set_title
var content: String = "":
    set = set_content

var _buttons := []

@onready var _title_label: Label = %TitleLabel
@onready var _content_label: RichTextLabel = %ContentLabel
@onready var _close_button: Button = %CloseButton
@onready var _button_bar: HBoxContainer = %ButtonBar


func _ready() -> void:
    _update_title()
    _update_content()
    _update_buttons()
    
    _close_button.pressed.connect(close_popup)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton && event.is_pressed():
        mark_click_handled()
        accept_event()


func _draw() -> void:
    var popup_origin := Vector2.ZERO

    # Draw border
    var border_color := get_theme_color("border_color", "InfoPopup")
    var border_width := get_theme_constant("border_width", "InfoPopup")
    var border_position := popup_origin - Vector2(border_width, border_width)
    var border_size := size + Vector2(border_width, border_width) * 2

    draw_rect(Rect2(border_position, border_size), border_color)

    # Draw content and title.
    var title_color := get_theme_color("title_color", "InfoPopup")
    var content_color := get_theme_color("content_color", "InfoPopup")
    var title_height := get_theme_constant("title_height", "InfoPopup")
    var title_size := Vector2(size.x, title_height)

    draw_rect(Rect2(popup_origin, size), content_color)
    draw_rect(Rect2(popup_origin, title_size), title_color)


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    if is_node_ready():
        _update_title()
        _update_content()
        _update_buttons()

    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)


func clear() -> void:
    title = "Information"
    content = ""

    _buttons.clear()
    
    if is_node_ready():
        for button in _button_bar.get_children():
            button.queue_free()
        
        _button_bar.visible = false
            
    custom_minimum_size = Vector2.ZERO
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
    size = Vector2.ZERO


func set_title(value: String) -> void:
    title = value
    _update_title()


func _update_title() -> void:
    if not is_node_ready():
        return

    _title_label.text = title


func set_content(value: String) -> void:
    content = value
    _update_content()


func _update_content() -> void:
    if not is_node_ready():
        return

    _content_label.text = content


func add_button(text: String, callback: Callable) -> Button:
    var button = Button.new()
    button.text = text
    button.pressed.connect(
        func():
            mark_click_handled()
            callback.call()
    )
    button.theme_type_variation = "LabelButton"

    _buttons.push_back(button)
    
    if is_node_ready():        
        _button_bar.add_child(button)
        _button_bar.visible = true
    
    return button


func _update_buttons() -> void:
    if not is_node_ready():
        return
    
    if _button_bar.get_child_count() == 0:
        var spacer = _button_bar.add_spacer(false)
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    for button in _buttons:
        if not button.get_parent():
            _button_bar.add_child(button)
            var spacer = _button_bar.add_spacer(false)
            spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _button_bar.visible = _buttons.size() > 1
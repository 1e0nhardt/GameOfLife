class_name SettingsPopup
extends PopupManager.PopupControl

var _rule := ""
var _size := -1

@onready var rule_line_edit: LineEdit = %RuleLineEdit
@onready var size_line_edit: LineEdit = %SizeLineEdit
@onready var cancel_button: Button = %CancelButton
@onready var apply_button: Button = %ApplyButton


func _ready() -> void:
    set_current_rule_and_size()
    cancel_button.pressed.connect(close_popup)
    apply_button.pressed.connect(
        func():
            apply_settings()
            close_popup()
    )


func save_current_rule_and_size(rule: String, a_size: int) -> void:
    _rule = rule
    _size = a_size


func set_current_rule_and_size() -> void:
    rule_line_edit.text = _rule
    size_line_edit.text = str(_size)


func apply_settings() -> void:
    var settings := {}
    settings["rule"] = rule_line_edit.text.strip_edges()
    settings["size"] = size_line_edit.text.strip_edges()
    if not settings["size"].is_valid_int():
        settings["size"] = -1
    else:
        settings["size"] = settings["size"].to_int()
    Controller.settings_applied.emit(settings)


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    if is_node_ready():
        set_current_rule_and_size()
        
    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)
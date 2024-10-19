class_name SearchPanelPopup
extends PopupManager.PopupControl

@onready var search_panel: SearchPanel = %SearchPanel

var _rle_code := ""


func _ready() -> void:
    search_panel.search_edit.text = _rle_code
    search_panel.ok_button.pressed.connect(close_popup)
    search_panel.cancel_button.pressed.connect(close_popup)


func save_rle_code(rle_code: String) -> void:
    _rle_code = rle_code


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    if is_node_ready():
        search_panel.search_edit.text = _rle_code
        
    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)


func foucus_search_edit() -> void:
    search_panel.search_edit.grab_focus()

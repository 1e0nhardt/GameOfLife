class_name SavePanelPopup
extends PopupManager.PopupControl

@onready var save_panel: SavePanel = %SavePanel

var _rle_code := ""
var _rle_size := Vector2i.ZERO
var _rle_rule := ""

# This method may be called only once for each node. After removing a node from the scene tree and adding it again, _ready will not be called a second time.
func _ready() -> void:
    save_panel.update_rle_label(_rle_code, _rle_size.x, _rle_size.y, _rle_rule)
    save_panel.update_object_preview(_rle_code, _rle_size.x, _rle_size.y)
    save_panel.save_file_button.pressed.connect(close_popup)
    save_panel.cancel_save_button.pressed.connect(close_popup)
    save_panel.save_db_button.pressed.connect(close_popup)


func save_rle_data(rle_code: String, x: int, y: int, rule: String) -> void:
    _rle_code = rle_code
    _rle_size = Vector2i(x, y)
    _rle_rule = rule


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    if is_node_ready(): # 第一次实例化的时候，还没有ready。后续从场景树中移除，再重新挂到场景树时，就已经是ready状态了。
        save_panel.update_rle_label(_rle_code, _rle_size.x, _rle_size.y, _rle_rule)
        save_panel.update_object_preview(_rle_code, _rle_size.x, _rle_size.y)
        
    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)


func foucus_name_edit() -> void:
    save_panel.name_edit.grab_focus()